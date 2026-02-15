import net from "node:net";

const LISTEN_HOST = process.env.LISTEN_HOST || "192.168.64.1";
const LISTEN_PORT = Number(process.env.LISTEN_PORT || 8080);
const TARGET_HOST = process.env.TARGET_HOST || "127.0.0.1";
const TARGET_PORT = Number(process.env.TARGET_PORT || 8080);

const server = net.createServer((client) => {
  const upstream = net.connect({ host: TARGET_HOST, port: TARGET_PORT });
  client.pipe(upstream);
  upstream.pipe(client);

  const closeBoth = () => {
    client.destroy();
    upstream.destroy();
  };

  client.on("error", closeBoth);
  upstream.on("error", closeBoth);
});

server.listen(LISTEN_PORT, LISTEN_HOST, () => {
  // Keep output compact for nohup logs.
  // eslint-disable-next-line no-console
  console.log(
    `headscale-vm-proxy listening ${LISTEN_HOST}:${LISTEN_PORT} -> ${TARGET_HOST}:${TARGET_PORT}`,
  );
});

server.on("error", (err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
