import { formatReceivedDate, formatUpdatedDate } from "@/lib/tracking/date-format";
import { statusLabel, statusTone } from "@/lib/tracking/status";
import type { PublicRepairTrackingData } from "@/lib/tracking/types";

type TrackingStatusCardProps = {
  data: PublicRepairTrackingData;
};

export function TrackingStatusCard({ data }: TrackingStatusCardProps) {
  const customerMessage = data.repair.customerMessage?.trim();

  return (
    <article className="mx-auto w-full max-w-xl rounded-3xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
      <header className="border-b border-slate-100 pb-6 text-center">
        <p className="text-sm font-medium uppercase tracking-[0.18em] text-slate-500">
          {data.shop.name}
        </p>
        {data.shop.subtitle ? (
          <p className="mt-2 text-sm text-slate-500">{data.shop.subtitle}</p>
        ) : null}
      </header>

      <div className="py-8 text-center">
        <p className="text-sm font-medium text-slate-500">Current Status</p>
        <div
          className={`mt-3 inline-flex rounded-2xl border px-5 py-3 text-xl font-semibold ${statusTone(
            data.repair.status,
          )}`}
        >
          {statusLabel(data.repair.status)}
        </div>
      </div>

      <dl className="grid gap-4 border-t border-slate-100 pt-6 text-sm">
        <div className="rounded-2xl bg-slate-50 p-4">
          <dt className="font-medium text-slate-500">Repair Code</dt>
          <dd className="mt-1 text-lg font-semibold text-slate-950">
            {data.repair.code}
          </dd>
        </div>

        <div className="rounded-2xl bg-slate-50 p-4">
          <dt className="font-medium text-slate-500">Device</dt>
          <dd className="mt-1 text-base font-semibold text-slate-950">
            {data.repair.device}
          </dd>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <div className="rounded-2xl bg-slate-50 p-4">
            <dt className="font-medium text-slate-500">Received</dt>
            <dd className="mt-1 font-semibold text-slate-950">
              {formatReceivedDate(data.repair.receivedAt)}
            </dd>
          </div>

          <div className="rounded-2xl bg-slate-50 p-4">
            <dt className="font-medium text-slate-500">Last updated</dt>
            <dd className="mt-1 font-semibold text-slate-950">
              {formatUpdatedDate(data.repair.updatedAt)}
            </dd>
          </div>
        </div>
      </dl>

      {customerMessage ? (
        <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-4">
          <h2 className="text-sm font-semibold text-slate-950">
            Message from the repair shop
          </h2>
          <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-slate-700">
            {customerMessage}
          </p>
        </section>
      ) : null}
    </article>
  );
}
