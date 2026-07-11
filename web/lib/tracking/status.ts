import type { RepairStatus } from "./types";

const statusLabels: Record<RepairStatus, string> = {
  received: "Received",
  diagnosing: "Diagnosing",
  waiting_for_customer_approval: "Waiting for customer approval",
  waiting_for_part: "Waiting for part",
  repairing: "Repairing",
  ready_for_pickup: "Ready for pickup",
  delivered: "Delivered",
  cancelled: "Cancelled",
};

const activeStatuses = new Set<RepairStatus>([
  "received",
  "diagnosing",
  "waiting_for_customer_approval",
  "waiting_for_part",
  "repairing",
]);

export function statusLabel(status: RepairStatus): string {
  return statusLabels[status] ?? "Status unavailable";
}

export function statusTone(status: RepairStatus): string {
  if (status === "ready_for_pickup") {
    return "border-emerald-200 bg-emerald-50 text-emerald-800";
  }

  if (status === "delivered") {
    return "border-slate-200 bg-white text-slate-800";
  }

  if (status === "cancelled") {
    return "border-rose-200 bg-rose-50 text-rose-800";
  }

  if (activeStatuses.has(status)) {
    return "border-amber-200 bg-amber-50 text-amber-900";
  }

  return "border-slate-200 bg-white text-slate-800";
}
