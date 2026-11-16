import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface EmailRecipient {
  invite_id?: string | null;
  institutional_email: string;
  full_name?: string | null;
  role_label?: string | null;
  scope_label?: string | null;
  activation_code: string;
  expires_at?: string | null;
}

interface InviteEmailPayload {
  recipients: EmailRecipient[];
}

function toBase64Utf8(text: string): string {
  const bytes = new TextEncoder().encode(text);
  let binary = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const slice = bytes.subarray(i, Math.min(i + chunkSize, bytes.length));
    binary += String.fromCharCode(...slice);
  }
  return btoa(binary);
}

function encodeMimeHeader(value: string): string {
  return `=?UTF-8?B?${toBase64Utf8(value)}?=`;
}

class SmtpTlsClient {
  private conn: Deno.TlsConn | null = null;
  private buffer = "";
  private decoder = new TextDecoder();
  private encoder = new TextEncoder();

  async connect(hostname: string, port: number): Promise<void> {
    this.conn = await Deno.connectTls({ hostname, port });
    await this.expectCode(220);
  }

  private async readLine(): Promise<string> {
    if (!this.conn) throw new Error("SMTP connection closed");
    while (!this.buffer.includes("\n")) {
      const chunk = new Uint8Array(4096);
      const n = await this.conn.read(chunk);
      if (n === null) throw new Error("Unexpected EOF from SMTP server");
      this.buffer += this.decoder.decode(chunk.subarray(0, n));
    }
    const idx = this.buffer.indexOf("\n");
    const line = this.buffer.slice(0, idx).replace(/\r$/, "");
    this.buffer = this.buffer.slice(idx + 1);
    return line;
  }

  private async readResponse(): Promise<{ code: number; lines: string[] }> {
    const lines: string[] = [];
    while (true) {
      const line = await this.readLine();
      lines.push(line);
      if (line.length >= 4 && line[3] === " ") {
        const code = Number.parseInt(line.slice(0, 3), 10);
        return { code, lines };
      }
      if (line.length === 3) {
        const code = Number.parseInt(line, 10);
        return { code, lines };
      }
    }
  }

  private async expectCode(expected: number | number[]): Promise<void> {
    const accepted = Array.isArray(expected) ? expected : [expected];
    const { code, lines } = await this.readResponse();
    if (!accepted.includes(code)) {
      throw new Error(`SMTP error ${code}: ${lines.join(" | ")}`);
    }
  }

  private async writeAll(data: string): Promise<void> {
    if (!this.conn) throw new Error("SMTP connection closed");
    const bytes = this.encoder.encode(data);
    let offset = 0;
    while (offset < bytes.length) {
      offset += await this.conn.write(bytes.subarray(offset));
    }
  }

  private async command(
    cmd: string,
    expected: number | number[],
  ): Promise<void> {
    await this.writeAll(`${cmd}\r\n`);
    await this.expectCode(expected);
  }

  async authLogin(user: string, appPassword: string): Promise<void> {
    await this.command("EHLO setu-supabase.local", 250);
    await this.command("AUTH LOGIN", 334);
    await this.command(toBase64Utf8(user), 334);
    await this.command(toBase64Utf8(appPassword), 235);
  }

  async sendMessage(
    fromEmail: string,
    fromName: string,
    toEmail: string,
    subject: string,
    textBody: string,
  ): Promise<void> {
    await this.command(`MAIL FROM:<${fromEmail}>`, 250);
    await this.command(`RCPT TO:<${toEmail}>`, [250, 251]);
    await this.command("DATA", 354);

    const headers = [
      `From: ${encodeMimeHeader(fromName)} <${fromEmail}>`,
      `To: <${toEmail}>`,
      `Subject: ${encodeMimeHeader(subject)}`,
      "MIME-Version: 1.0",
      "Content-Type: text/plain; charset=UTF-8",
      "Content-Transfer-Encoding: base64",
      "",
    ].join("\r\n");

    const base64Body = toBase64Utf8(textBody);
    const wrappedBody = base64Body.replace(/.{1,76}/g, "$&\r\n");
    await this.writeAll(`${headers}\r\n${wrappedBody}\r\n.\r\n`);
    await this.expectCode(250);
  }

  async quit(): Promise<void> {
    try {
      if (this.conn) {
        await this.writeAll("QUIT\r\n");
      }
    } catch {
      // Ignore quit error on closing.
    } finally {
      try {
        this.conn?.close();
      } catch {
        // Already closed.
      }
      this.conn = null;
    }
  }
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function buildInviteBody(recipient: EmailRecipient): string {
  const greetingName = recipient.full_name?.trim()
    ? `Hola ${recipient.full_name.trim()},`
    : "Hola,";
  const roleLine = recipient.role_label?.trim()
    ? `- Rol autorizado: ${recipient.role_label.trim()}\n`
    : "";
  const scopeLine = recipient.scope_label?.trim()
    ? `- Ámbito / centro: ${recipient.scope_label.trim()}\n`
    : "";
  const expiresLine = recipient.expires_at?.trim()
    ? `- Vigencia límite: ${recipient.expires_at.trim()}\n`
    : "";

  return [
    greetingName,
    "",
    "Tu acceso para personal autorizado en SéTú fue aprobado y emitido por supervisión del MINED.",
    "",
    "Detalle de tu activación:",
    `- Correo vinculado: ${recipient.institutional_email}`,
    roleLine.trimEnd(),
    scopeLine.trimEnd(),
    `- Código individual de un solo uso: ${recipient.activation_code}`,
    expiresLine.trimEnd(),
    "",
    "Pasos para activar tu cuenta en la app SéTú:",
    "1. Abrí SéTú y tocá «Personal autorizado» -> «Registrar cuenta».",
    "2. Creá tu cuenta con este mismo correo y elegí tu contraseña.",
    "3. Abrí el enlace de confirmación que llegará a tu bandeja.",
    "4. Ingresá el código individual de arriba y completá tu nombre.",
    "",
    "Este código es personal e intransferible.",
    "Equipo SéTú · MINED",
  ]
    .filter((line, idx, arr) => !(line === "" && arr[idx - 1] === ""))
    .join("\n");
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse(405, { ok: false, error: "method_not_allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(500, { ok: false, error: "missing_supabase_env" });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length).trim()
    : "";
  if (!jwt) {
    return jsonResponse(401, { ok: false, error: "unauthorized" });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await adminClient.auth.getUser(
    jwt,
  );
  if (userError || !userData.user) {
    return jsonResponse(401, { ok: false, error: "invalid_jwt" });
  }

  const { data: membership } = await adminClient
    .from("staff_memberships")
    .select("id")
    .eq("user_id", userData.user.id)
    .eq("role", "mined_supervisor")
    .eq("active", true)
    .is("revoked_at", null)
    .limit(1)
    .maybeSingle();

  if (!membership) {
    return jsonResponse(403, {
      ok: false,
      error: "forbidden_mined_supervisor_required",
    });
  }

  let payload: InviteEmailPayload;
  try {
    payload = (await req.json()) as InviteEmailPayload;
  } catch {
    return jsonResponse(400, { ok: false, error: "invalid_json" });
  }

  const recipients = Array.isArray(payload.recipients) ? payload.recipients : [];
  if (recipients.length === 0 || recipients.length > 200) {
    return jsonResponse(400, { ok: false, error: "invalid_recipients_count" });
  }

  const smtpUser = (Deno.env.get("GMAIL_SMTP_USER") ?? "").trim();
  const smtpPassword = (Deno.env.get("GMAIL_SMTP_APP_PASSWORD") ?? "").replace(
    /\s+/g,
    "",
  );
  const fromName = (Deno.env.get("GMAIL_SMTP_FROM_NAME") ?? "SéTú · MINED")
    .trim();

  if (!smtpUser || !smtpPassword) {
    return jsonResponse(200, {
      ok: false,
      configured: false,
      sent_count: 0,
      failed_count: recipients.length,
      reason: "smtp_not_configured",
    });
  }

  const client = new SmtpTlsClient();
  const failures: Array<{ email: string; error: string }> = [];
  let sentCount = 0;

  try {
    await client.connect("smtp.gmail.com", 465);
    await client.authLogin(smtpUser, smtpPassword);

    for (const item of recipients) {
      const email = (item.institutional_email ?? "").trim();
      const code = (item.activation_code ?? "").trim();
      if (!email || !code) {
        failures.push({ email, error: "missing_email_or_code" });
        continue;
      }
      try {
        await client.sendMessage(
          smtpUser,
          fromName,
          email,
          "SéTú · Tu código individual de activación",
          buildInviteBody(item),
        );
        sentCount += 1;
        if (item.invite_id) {
          await adminClient.from("staff_invite_events").insert({
            invite_id: item.invite_id,
            event_type: "email_sent",
            actor_user_id: userData.user.id,
            details: `Código enviado por correo SMTP a ${email}`,
          });
        }
      } catch (err) {
        failures.push({
          email,
          error: err instanceof Error ? err.message : String(err),
        });
      }
    }
  } catch (err) {
    return jsonResponse(200, {
      ok: false,
      configured: true,
      sent_count: sentCount,
      failed_count: recipients.length - sentCount,
      reason: err instanceof Error ? err.message : String(err),
    });
  } finally {
    await client.quit();
  }

  return jsonResponse(200, {
    ok: failures.length === 0,
    configured: true,
    sent_count: sentCount,
    failed_count: failures.length,
    failures,
  });
});
