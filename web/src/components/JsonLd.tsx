/**
 * Structured data for search engines. It's a data block, not a script the browser runs, so the strict
 * Content-Security-Policy doesn't apply to it. `<` is escaped so no string in the data can close the tag.
 */
export default function JsonLd({ data }: { data: object }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, "\\u003c") }}
    />
  );
}
