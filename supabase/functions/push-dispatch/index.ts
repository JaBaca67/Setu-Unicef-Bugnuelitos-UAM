import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type PushEventType =
  | "new_alert_dispatch"
  | "staff_new_message"
  | "student_chat_enabled"
  | "student_new_message";

interface DispatchPayload {
  event_type: PushEventType;
  target_user_id?: string | null;
  target_case_id?: string | null;
}

interface FirebaseServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const MESSAGES: Record<PushEventType, { title: string; body: string }> = {
  new_alert_dispatch: {
    title: "SéTú · Mesa de escucha",
    body: "Tenés una nueva alerta disponible para atender.",
  },
  staff_new_message: {
    title: "SéTú · Seguimiento",
    body: "Tenés un nuevo mensaje en uno de tus casos.",
  },
  student_chat_enabled: {
    title: "SéTú",
    body: "Un profesional ya puede conversar con vos. Entrá a tu seguimiento cuando podás.",
  },
  student_new_message: {
    title: "SéTú",
    body: "Tenés un nuevo mensaje en tu seguimiento.",
  },
};

function base64UrlEncode(input: Uint8Array | string): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

async function getFirebaseAccessToken(
  sa: FirebaseServiceAccount,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claimSet = base64UrlEncode(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsignedJwt = `${header}.${claimSet}`;

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedJwt),
  );
  const assertion = `${unsignedJwt}.${base64UrlEncode(new Uint8Array(signature))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!tokenRes.ok) {
    const errText = await tokenRes.text();
    throw new Error(`OAuth token error (${tokenRes.status}): ${errText}`);
  }
  const tokenJson = (await tokenRes.json()) as { access_token?: string };
  if (!tokenJson.access_token) {
    throw new Error("Missing access_token in Google OAuth response");
  }
  return tokenJson.access_token;
}

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const expectedSecret = Deno.env.get("PUSH_DISPATCH_SECRET") ?? "";
  const providedSecret = req.headers.get("x-push-dispatch-secret") ?? "";
  if (
    !expectedSecret ||
    !providedSecret ||
    !constantTimeEqual(expectedSecret, providedSecret)
  ) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!saRaw || !supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: "missing_configuration" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const payload = (await req.json()) as DispatchPayload;
  const copy = MESSAGES[payload.event_type];
  if (!copy) {
    return new Response(JSON.stringify({ error: "invalid_event_type" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let query = supabase.from("push_device_tokens").select("id, fcm_token");
  if (payload.target_user_id) {
    query = query.eq("role_scope", "staff").eq("user_id", payload.target_user_id);
  } else if (payload.target_case_id) {
    query = query.eq("role_scope", "student").eq("case_id", payload.target_case_id);
  } else {
    return new Response(JSON.stringify({ sent: 0 }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { data: tokens, error: queryError } = await query;
  if (queryError) {
    return new Response(JSON.stringify({ error: "token_query_failed" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const sa = JSON.parse(saRaw) as FirebaseServiceAccount;
  const accessToken = await getFirebaseAccessToken(sa);
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  let sent = 0;
  let failed = 0;
  const staleTokenIds: string[] = [];

  for (const row of tokens) {
    const fcmRes = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: row.fcm_token,
          notification: {
            title: copy.title,
            body: copy.body,
          },
          android: {
            priority: "high",
            // Canal nativo de importancia alta (aviso flotante tipo mensajería).
            notification: {
              channel_id: "setu_avisos",
              icon: "ic_stat_setu",
              default_sound: true,
              default_vibrate_timings: true,
              notification_priority: "PRIORITY_MAX",
              visibility: "PRIVATE",
            },
          },
          data: {
            event_type: payload.event_type,
          },
        },
      }),
    });

    if (fcmRes.ok) {
      sent += 1;
      continue;
    }

    failed += 1;
    const errBody = await fcmRes.text();
    let fcmErrorCode = "";
    try {
      const parsed = JSON.parse(errBody) as {
        error?: { status?: string; details?: Array<{ errorCode?: string }> };
      };
      fcmErrorCode =
        parsed.error?.details?.[0]?.errorCode ?? parsed.error?.status ?? "";
    } catch {
      fcmErrorCode = "";
    }
    console.error("push-dispatch FCM error", {
      eventType: payload.event_type,
      status: fcmRes.status,
      fcmErrorCode,
    });
    if (
      fcmRes.status === 404 ||
      errBody.includes("UNREGISTERED") ||
      errBody.includes("INVALID_ARGUMENT")
    ) {
      staleTokenIds.push(row.id);
    }
  }

  if (staleTokenIds.length > 0) {
    await supabase.from("push_device_tokens").delete().in("id", staleTokenIds);
  }

  return new Response(
    JSON.stringify({ sent, pruned: staleTokenIds.length, failed }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
});
