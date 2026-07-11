import { StateMessage } from "@/components/StateMessage";
import { TrackingStatusCard } from "@/components/TrackingStatusCard";
import { getPublicRepairTracking } from "@/lib/tracking/client";

type TrackingPageProps = {
  params: Promise<{
    token?: string;
  }>;
};

export default async function TrackingPage({ params }: TrackingPageProps) {
  const { token } = await params;
  const result = await getPublicRepairTracking(token ?? "");

  return (
    <main className="min-h-screen px-4 py-8 sm:py-12">
      {result.state === "found" ? (
        <TrackingStatusCard data={result.data} />
      ) : result.state === "not-found" ? (
        <StateMessage
          title="Repair not found"
          message="Please check the tracking link on your repair ticket."
        />
      ) : (
        <StateMessage
          title="Tracking temporarily unavailable"
          message="Please try again later."
        />
      )}

      <footer className="mx-auto mt-6 max-w-xl text-center text-xs text-slate-500">
        Powered by Nova Repair
      </footer>
    </main>
  );
}
