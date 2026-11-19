// How agents start OpenPixel's MCP server, shared by the download page and the footer.

export const EXE = "/Applications/OpenPixel.app/Contents/MacOS/OpenPixel";

/** Cursor's one-click MCP install link (the same one the app's Agents page uses). */
export const CURSOR_LINK = `cursor://anysphere.cursor-deeplink/mcp/install?name=openpixel&config=${encodeURIComponent(
  Buffer.from(JSON.stringify({ command: EXE, args: ["--mcp"] })).toString("base64"),
)}`;
