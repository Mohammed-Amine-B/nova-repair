export type RepairStatus =
  | "received"
  | "diagnosing"
  | "waiting_for_customer_approval"
  | "waiting_for_part"
  | "repairing"
  | "ready_for_pickup"
  | "delivered"
  | "cancelled";

export type PublicRepairTrackingData = {
  contractVersion: number;
  shop: {
    name: string;
    subtitle: string | null;
  };
  repair: {
    code: string;
    device: string;
    status: RepairStatus;
    customerMessage: string | null;
    receivedAt: string;
    updatedAt: string;
  };
};

export type PublicTrackingResponse =
  | {
      ok: true;
      data: PublicRepairTrackingData;
    }
  | {
      ok: false;
      error: string;
      message?: string;
    };
