export function kbDetailPath(id: string) {
  return "/kb/?id=" + encodeURIComponent(id);
}

export function kbChatPath(id: string) {
  return "/chat/?id=" + encodeURIComponent(id);
}
