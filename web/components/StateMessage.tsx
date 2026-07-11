type StateMessageProps = {
  title: string;
  message: string;
};

export function StateMessage({ title, message }: StateMessageProps) {
  return (
    <section className="mx-auto w-full max-w-xl rounded-3xl border border-slate-200 bg-white p-8 text-center shadow-sm">
      <h1 className="text-2xl font-semibold text-slate-950">{title}</h1>
      <p className="mt-3 text-sm leading-6 text-slate-600">{message}</p>
    </section>
  );
}
