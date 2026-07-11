const appName = process.env.NEXT_PUBLIC_APP_NAME ?? "Nova Repair";

export default function HomePage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-10">
      <section className="w-full max-w-xl rounded-3xl border border-slate-200 bg-white p-8 text-center shadow-sm">
        <p className="text-sm font-medium uppercase tracking-[0.18em] text-slate-500">
          {appName}
        </p>
        <h1 className="mt-4 text-3xl font-semibold tracking-tight text-slate-950">
          Repair tracking
        </h1>
        <p className="mt-4 text-base leading-7 text-slate-600">
          Scan your repair ticket QR code to track your repair.
        </p>
      </section>
    </main>
  );
}
