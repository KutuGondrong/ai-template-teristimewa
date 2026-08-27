/** Suppress benign dev-server socket resets (Cursor preview, HMR, health checks). */
function isBenignDevSocketError(reason) {
  if (!reason) return false;
  const code = reason.code ?? reason.errno;
  const msg = String(reason.message ?? reason);
  return (
    code === "ECONNRESET" ||
    code === "ECONNABORTED" ||
    msg.includes("ECONNRESET") ||
    msg.includes("ECONNABORTED")
  );
}

const originalOn = process.on.bind(process);
process.on = (event, listener) => {
  if (event !== "unhandledRejection" || typeof listener !== "function") {
    return originalOn(event, listener);
  }
  return originalOn(event, (reason) => {
    if (isBenignDevSocketError(reason)) return;
    listener(reason);
  });
};
