import type { ReactNode } from "react";

interface LegalLayoutProps {
  title: string;
  lastUpdated: string;
  children: ReactNode;
}

export default function LegalLayout({
  title,
  lastUpdated,
  children,
}: LegalLayoutProps) {
  return (
    <article className="pt-32 pb-24">
      <div className="mx-auto max-w-3xl px-6 lg:px-8">
        {/* Header */}
        <header className="mb-12">
          <nav aria-label="Breadcrumb" className="mb-6">
            <ol className="flex items-center gap-2 text-sm text-stone-400 dark:text-stone-500">
              <li>
                <a
                  href="/"
                  className="hover:text-stone-600 dark:hover:text-stone-300 transition-colors"
                >
                  Home
                </a>
              </li>
              <li aria-hidden="true">/</li>
              <li className="text-stone-600 dark:text-stone-300">{title}</li>
            </ol>
          </nav>
          <h1 className="text-4xl sm:text-5xl font-bold tracking-tight text-stone-900 dark:text-stone-50">
            {title}
          </h1>
          <p className="mt-3 text-sm text-stone-500 dark:text-stone-400">
            Last updated: {lastUpdated}
          </p>
        </header>

        {/* Legal content */}
        <div className="prose prose-stone dark:prose-invert max-w-none prose-headings:scroll-mt-20 prose-headings:font-semibold prose-h2:text-2xl prose-h2:mt-10 prose-h2:mb-4 prose-h3:text-lg prose-h3:mt-8 prose-h3:mb-3 prose-p:leading-relaxed prose-p:text-stone-600 prose-p:dark:text-stone-400 prose-li:text-stone-600 prose-li:dark:text-stone-400 prose-a:text-amber-600 prose-a:dark:text-amber-400 prose-a:no-underline hover:prose-a:underline prose-strong:text-stone-800 prose-strong:dark:text-stone-200">
          {children}
        </div>
      </div>
    </article>
  );
}
