export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8">
      <div className="max-w-2xl text-center">
        <h1 className="text-4xl font-bold tracking-tight text-gray-900 sm:text-6xl">
          StoreScorer
        </h1>
        <p className="mt-6 text-lg leading-8 text-gray-600">
          AI-powered e-commerce store audits with actionable recommendations
          to improve your conversions.
        </p>
        <div className="mt-10 flex items-center justify-center gap-x-6">
          <a
            href="/audit"
            className="rounded-md bg-primary-600 px-6 py-3 text-sm font-semibold text-white shadow-sm hover:bg-primary-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600"
          >
            Get Your Free Audit
          </a>
          <a href="/about" className="text-sm font-semibold leading-6 text-gray-900">
            Learn more <span aria-hidden="true">→</span>
          </a>
        </div>
      </div>
    </main>
  );
}
