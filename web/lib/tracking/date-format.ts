const receivedFormatter = new Intl.DateTimeFormat("en", {
  month: "short",
  day: "numeric",
  year: "numeric",
});

const updatedFormatter = new Intl.DateTimeFormat("en", {
  month: "short",
  day: "numeric",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
});

export function formatReceivedDate(value: string): string {
  return formatDate(value, receivedFormatter);
}

export function formatUpdatedDate(value: string): string {
  return formatDate(value, updatedFormatter);
}

function formatDate(value: string, formatter: Intl.DateTimeFormat): string {
  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return "Date unavailable";
  }

  return formatter.format(date);
}
