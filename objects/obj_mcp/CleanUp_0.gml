/// @description MCP link - close
// obj_mcp : Clean Up. Close the socket and free the receive buffer.
if (mcp_socket >= 0) network_destroy(mcp_socket);
mcp_socket = -1;
if (mcp_rx >= 0 && buffer_exists(mcp_rx)) buffer_delete(mcp_rx);
mcp_rx = -1;
