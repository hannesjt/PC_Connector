export function useToast() {
  const message = useState<string | null>("toast", () => null);
  let timer: ReturnType<typeof setTimeout> | null = null;

  function show(msg: string, durationMs = 2800): void {
    message.value = msg;
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => (message.value = null), durationMs);
  }

  return { message, show };
}
