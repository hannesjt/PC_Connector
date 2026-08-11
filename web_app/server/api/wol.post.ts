import dgram from "node:dgram";

function buildMagicPacket(mac: string): Buffer {
  const clean = String(mac).replace(/[-:\s]/g, "");
  if (!/^[0-9a-fA-F]{12}$/.test(clean)) {
    throw new Error(`Invalid MAC address: ${mac}`);
  }
  const macBytes = Buffer.from(clean, "hex");
  const packet = Buffer.alloc(6 + 16 * 6, 0xff);
  for (let i = 0; i < 16; i++) {
    macBytes.copy(packet, 6 + i * 6);
  }
  return packet;
}

export default defineEventHandler(async (event) => {
  const body = await readBody<{
    mac?: string;
    broadcast?: string;
    port?: number;
  }>(event);
  const { mac, broadcast = "255.255.255.255", port = 9 } = body || {};

  let packet: Buffer;
  try {
    packet = buildMagicPacket(mac || "");
  } catch (e: any) {
    setResponseStatus(event, 400);
    return { success: false, error: e.message };
  }

  return await new Promise((resolve) => {
    const socket = dgram.createSocket("udp4");
    socket.bind(() => {
      socket.setBroadcast(true);
      socket.send(packet, 0, packet.length, port, broadcast, (err) => {
        socket.close();
        if (err) {
          setResponseStatus(event, 500);
          resolve({ success: false, error: err.message });
        } else {
          resolve({ success: true });
        }
      });
    });
  });
});
