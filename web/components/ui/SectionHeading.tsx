interface SectionHeadingProps {
  eyebrow?: string;
  title: string;
  description?: string;
  align?: "left" | "center";
}

export default function SectionHeading({
  eyebrow,
  title,
  description,
  align = "center",
}: SectionHeadingProps) {
  const alignment = align === "center" ? "text-center mx-auto" : "text-left";

  return (
    <div className={`max-w-2xl ${alignment}`}>
      {eyebrow && (
        <p className="text-sm font-semibold tracking-widest uppercase text-amber-600 dark:text-amber-400 mb-3">
          {eyebrow}
        </p>
      )}
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight text-stone-900 dark:text-stone-50 text-balance">
        {title}
      </h2>
      {description && (
        <p className="mt-4 text-lg text-stone-500 dark:text-stone-400 text-pretty leading-relaxed">
          {description}
        </p>
      )}
    </div>
  );
}
