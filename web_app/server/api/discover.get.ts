import dgram from "node:dgram";

const DISCOVERY_PORT = 8421;
const DISCOVERY_MAGIC = "PCCONNECTOR_DISCOVER";

export default defineEventHandler(async () => {
  return await new Promise((resolve) => {
    const socket = dgram.createSocket("udp4");
    const agents: {
      name: string;
      ip: string;
      port: number;
      mac: string;
    }[] = [];
    const seen = new Set<string>();
    let finished = false;

    const finish = () => {
      if (finished) return;
      finished = true;
      try {
        socket.close();
      } catch {}
      resolve(agents);
    };

    socket.on("message", (data, rinfo) => {
      try {
        const j = JSON.parse(data.toString());
        const key = `${rinfo.address}:${j.port}`;
        if (!seen.has(key)) {
          seen.add(key);
          agents.push({
            name: j.name,
            ip: rinfo.address,
            port: j.port,
            mac: j.mac,
          });
        }
      } catch {}
    });
    socket.on("error", finish);

    socket.bind(() => {
      socket.setBroadcast(true);
      const msg = Buffer.from(DISCOVERY_MAGIC);
      socket.send(msg, 0, msg.length, DISCOVERY_PORT, "255.255.255.255");
    });

    setTimeout(finish, 3000);
  });
});
