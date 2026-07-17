<?xml version="1.0" encoding="UTF-8"?>
<!--
  OIML STS → HTML XSLT Template

  Forked and adapted from sts4i-tools/nisosts2html/nisosts2html.xsl.
  This XSLT 1.0 stylesheet is compatible with Nokogiri's XSLT processor.

  It renders OIML NISO STS XML to semantic HTML that can be compared
  element-by-element against Metanorma's HTML output for content
  parity validation.
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                exclude-result-prefixes="xlink mml">

  <xsl:output method="html" encoding="UTF-8" indent="yes"
              doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"
              doctype-system="http://www.w3.org/TR/html4/loose.dtd"/>

  <xsl:template match="/">
    <html>
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>OIML STS Document</title>
        <style>
          /* OIML STS HTML rendering — forked from sts4i-tools/nisosts.css
             with OIML-specific typography and layout. */
          :root {
            --oiml-blue: #005a9c;
            --oiml-dark: #1a1a1a;
            --oiml-light: #f7f9fc;
            --oiml-border: #d0d7de;
            --oiml-accent: #6a737d;
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI",
                         "Helvetica Neue", Arial, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            color: var(--oiml-dark);
            background: #fff;
            margin: 0;
            padding: 2em 3em;
            max-width: 960px;
            margin: 0 auto;
          }
          @media print {
            body { padding: 0; max-width: none; }
            a { color: black; text-decoration: none; }
          }
          /* Front matter */
          header.doc-meta {
            border-bottom: 2px solid var(--oiml-blue);
            padding-bottom: 1.5em;
            margin-bottom: 2em;
          }
          .oiml-logo {
            width: 120px;
            height: 105px;
            margin-bottom: 1em;
            background-image: url("oiml-logo.svg");
            background-repeat: no-repeat;
            background-size: contain;
          }
          .doc-id {
            display: inline-block;
            background: var(--oiml-blue);
            color: white;
            padding: 0.3em 0.8em;
            font-weight: 600;
            letter-spacing: 0.02em;
            border-radius: 3px;
          }
          h1.title {
            font-size: 2em;
            font-weight: 600;
            margin: 0.8em 0 0;
            line-height: 1.25;
          }
          /* Headings */
          h1, h2, h3, h4, h5, h6 {
            color: var(--oiml-dark);
            font-weight: 600;
            line-height: 1.3;
            margin-top: 1.5em;
            margin-bottom: 0.5em;
          }
          h1 { font-size: 1.75em; border-bottom: 1px solid var(--oiml-border); padding-bottom: 0.3em; }
          h2 { font-size: 1.5em; }
          h3 { font-size: 1.25em; }
          h4 { font-size: 1.1em; }
          h5, h6 { font-size: 1em; }
          /* Sections */
          section {
            margin: 1.5em 0;
          }
          section > section {
            margin-left: 0;
          }
          /* Paragraphs */
          p {
            margin: 0.6em 0;
          }
          /* Labels */
          .label {
            display: inline-block;
            font-weight: 600;
            color: var(--oiml-blue);
            margin-right: 0.3em;
          }
          /* Lists */
          ul, ol {
            margin: 0.5em 0;
            padding-left: 1.8em;
          }
          li {
            margin: 0.25em 0;
          }
          dl {
            margin: 1em 0;
            border-left: 3px solid var(--oiml-border);
            padding-left: 1em;
          }
          dt {
            font-weight: 600;
            color: var(--oiml-blue);
            margin-top: 0.5em;
          }
          dd {
            margin-left: 1em;
            margin-bottom: 0.5em;
          }
          /* Tables */
          table {
            border-collapse: collapse;
            margin: 1em 0;
            width: 100%;
            font-size: 0.95em;
          }
          table-wrap {
            display: block;
            margin: 1.5em 0;
            page-break-inside: avoid;
          }
          caption, figcaption {
            caption-side: bottom;
            font-size: 0.9em;
            color: var(--oiml-accent);
            padding-top: 0.4em;
            text-align: left;
          }
          th, td {
            border: 1px solid var(--oiml-border);
            padding: 0.4em 0.7em;
            text-align: left;
            vertical-align: top;
          }
          thead th {
            background: var(--oiml-light);
            font-weight: 600;
            border-bottom-width: 2px;
          }
          tbody tr:nth-child(even) {
            background: var(--oiml-light);
          }
          /* Figures */
          figure, .fig {
            margin: 1.5em 0;
            text-align: center;
            page-break-inside: avoid;
          }
          figure img, .fig img {
            max-width: 100%;
            height: auto;
          }
          figure figcaption {
            margin-top: 0.5em;
            font-style: italic;
          }
          /* Notes and examples */
          .note, .non-normative-note, .normative-note,
          .example, .non-normative-example, .normative-example {
            background: var(--oiml-light);
            border-left: 3px solid var(--oiml-blue);
            padding: 0.6em 1em;
            margin: 1em 0;
            border-radius: 0 3px 3px 0;
          }
          /* Inline */
          a {
            color: var(--oiml-blue);
            text-decoration: none;
          }
          a:hover { text-decoration: underline; }
          .footnote, sup {
            font-size: 0.8em;
            vertical-align: super;
            line-height: 0;
          }
          .footnote-ref {
            color: var(--oiml-blue);
            font-weight: 600;
          }
          /* Bibliography */
          .ref-list {
            margin-top: 2em;
            padding-left: 0;
            list-style: none;
          }
          p.biblio {
            padding-left: 2em;
            text-indent: -2em;
            margin: 0.5em 0;
          }
          .citation { font-style: italic; }
          .std-ref { font-weight: 600; color: var(--oiml-blue); }
          /* MathML passthrough */
          .stem, .formula {
            display: inline-block;
            font-family: "STIX Two Math", "Cambria Math", serif;
          }
          .formula {
            display: block;
            margin: 0.8em 0;
            text-align: center;
          }
          /* Code */
          code, pre, .preformat {
            font-family: "SF Mono", "Monaco", "Inconsolata", "Consolas", monospace;
            font-size: 0.9em;
            background: var(--oiml-light);
          }
          pre, .preformat {
            padding: 0.8em 1em;
            overflow-x: auto;
            border-radius: 3px;
            border: 1px solid var(--oiml-border);
          }
          code {
            padding: 0.1em 0.3em;
            border-radius: 2px;
          }
          /* Blockquotes */
          blockquote, .disp-quote {
            border-left: 4px solid var(--oiml-border);
            padding: 0.5em 1em;
            margin: 1em 0;
            color: var(--oiml-accent);
            font-style: italic;
          }
        </style>
      </head>
      <body>
        <xsl:apply-templates select="standard"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="standard">
    <xsl:apply-templates select="front"/>
    <xsl:apply-templates select="body"/>
    <xsl:apply-templates select="back"/>
  </xsl:template>

  <xsl:template match="processing-meta"/>

  <!-- Front matter -->
  <xsl:template match="front">
    <xsl:apply-templates select="iso-meta | std-meta | reg-meta"/>
  </xsl:template>

  <xsl:template match="iso-meta | std-meta | reg-meta">
    <header class="doc-meta">
      <div class="oiml-logo"></div>
      <xsl:if test="std-ident">
        <span class="doc-id">
          <xsl:value-of select="std-ident/originator"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="std-ident/doc-number"/>
        </span>
      </xsl:if>
      <xsl:if test="title-wrap/main | title">
        <h1 class="title">
          <xsl:value-of select="title-wrap/main | title"/>
        </h1>
      </xsl:if>
      <xsl:if test="permissions/copyright-statement">
        <p class="copyright">
          <xsl:value-of select="normalize-space(permissions/copyright-statement)"/>
          <xsl:if test="permissions/copyright-holder and normalize-space(permissions/copyright-holder)">
            <xsl:text> </xsl:text>
            <xsl:value-of select="permissions/copyright-holder"/>
          </xsl:if>
        </p>
      </xsl:if>
    </header>
  </xsl:template>

  <!-- Body -->
  <xsl:template match="body">
    <main>
      <xsl:apply-templates/>
    </main>
  </xsl:template>

  <!-- Back -->
  <xsl:template match="back">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Sections — pass depth via xsl:param so titles emit the right
       heading level (h1 for top-level, h2 for sub, etc.). -->
  <xsl:template match="sec | app">
    <xsl:param name="depth" select="1"/>
    <section>
      <xsl:if test="@id">
        <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates>
        <xsl:with-param name="depth" select="$depth"/>
      </xsl:apply-templates>
    </section>
  </xsl:template>

  <xsl:template match="app-group">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Labels and titles -->
  <xsl:template match="label">
    <span class="label"><xsl:apply-templates/><xsl:text> </xsl:text></span>
  </xsl:template>

  <!-- Title: depth-aware. Compute depth from ancestor count so we don't
       need to thread xsl:param through every apply-templates call. -->
  <xsl:template match="sec/title | app/title">
    <xsl:variable name="depth_raw" select="count(ancestor::sec) + count(ancestor::app)"/>
    <xsl:variable name="level">
      <xsl:choose>
        <xsl:when test="$depth_raw >= 6">6</xsl:when>
        <xsl:when test="$depth_raw < 1">1</xsl:when>
        <xsl:otherwise><xsl:value-of select="$depth_raw"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="h{$level}">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- Title that is a direct child of ref-list: render as h1 to match
       MN HTML's Bibliography/References section headings. -->
  <xsl:template match="ref-list/title">
    <h1><xsl:apply-templates/></h1>
  </xsl:template>

  <!-- Figure / table captions. -->
  <xsl:template match="fig/caption | table-wrap/caption">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="title">
    <h2><xsl:apply-templates/></h2>
  </xsl:template>

  <!-- Paragraphs -->
  <xsl:template match="p">
    <p>
      <xsl:if test="@id">
        <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- Lists -->
  <xsl:template match="list">
    <xsl:choose>
      <xsl:when test="@list-type = 'order'">
        <ol><xsl:apply-templates/></ol>
      </xsl:when>
      <xsl:otherwise>
        <ul><xsl:apply-templates/></ul>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="list-item">
    <li><xsl:apply-templates/></li>
  </xsl:template>

  <!-- Definition lists -->
  <xsl:template match="def-list">
    <dl><xsl:apply-templates/></dl>
  </xsl:template>

  <xsl:template match="def-item">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="def-item/term">
    <dt><p><xsl:apply-templates/></p></dt>
  </xsl:template>

  <xsl:template match="def-item/def">
    <dd><xsl:apply-templates/></dd>
  </xsl:template>

  <!-- Tables -->
  <xsl:template match="table-wrap">
    <div class="table-wrap">
      <xsl:if test="@id">
        <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="table">
    <table><xsl:apply-templates/></table>
  </xsl:template>

  <xsl:template match="thead">
    <thead><xsl:apply-templates/></thead>
  </xsl:template>

  <xsl:template match="tbody">
    <tbody><xsl:apply-templates/></tbody>
  </xsl:template>

  <xsl:template match="tr">
    <tr><xsl:apply-templates/></tr>
  </xsl:template>

  <xsl:template match="th">
    <th>
      <xsl:if test="@align"><xsl:attribute name="style">text-align:<xsl:value-of select="@align"/></xsl:attribute></xsl:if>
      <xsl:apply-templates/>
    </th>
  </xsl:template>

  <xsl:template match="td">
    <td>
      <xsl:if test="@align"><xsl:attribute name="style">text-align:<xsl:value-of select="@align"/></xsl:attribute></xsl:if>
      <xsl:apply-templates/>
    </td>
  </xsl:template>

  <!-- Figures -->
  <xsl:template match="fig">
    <figure>
      <xsl:if test="@id">
        <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </figure>
  </xsl:template>

  <xsl:template match="caption">
    <figcaption><xsl:apply-templates/></figcaption>
  </xsl:template>

  <xsl:template match="graphic">
    <img>
      <xsl:attribute name="src"><xsl:value-of select="@xlink:href"/></xsl:attribute>
      <xsl:if test="@alttext">
        <xsl:attribute name="alt"><xsl:value-of select="@alttext"/></xsl:attribute>
      </xsl:if>
    </img>
  </xsl:template>

  <!-- Formulas -->
  <xsl:template match="disp-formula">
    <div class="formula"><xsl:apply-templates/></div>
  </xsl:template>

  <xsl:template match="inline-formula">
    <span class="formula"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- MathML passthrough -->
  <xsl:template match="mml:math">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!-- Inline formatting -->
  <xsl:template match="italic">
    <em><xsl:apply-templates/></em>
  </xsl:template>

  <xsl:template match="bold">
    <strong><xsl:apply-templates/></strong>
  </xsl:template>

  <xsl:template match="monospace">
    <code><xsl:apply-templates/></code>
  </xsl:template>

  <xsl:template match="sub">
    <sub><xsl:apply-templates/></sub>
  </xsl:template>

  <xsl:template match="sup">
    <sup><xsl:apply-templates/></sup>
  </xsl:template>

  <xsl:template match="underline">
    <u><xsl:apply-templates/></u>
  </xsl:template>

  <xsl:template match="strike">
    <del><xsl:apply-templates/></del>
  </xsl:template>

  <!-- Links -->
  <xsl:template match="ext-link | uri">
    <a>
      <xsl:attribute name="href"><xsl:value-of select="@xlink:href"/></xsl:attribute>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <!-- Cross-references -->
  <xsl:template match="xref">
    <a>
      <xsl:attribute name="href">#<xsl:value-of select="@rid"/></xsl:attribute>
      <xsl:choose>
        <xsl:when test="normalize-space()">
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@rid"/>
        </xsl:otherwise>
      </xsl:choose>
    </a>
  </xsl:template>

  <!-- Footnotes -->
  <xsl:template match="fn">
    <span class="footnote">
      <xsl:if test="@id">
        <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- Notes and examples -->
  <xsl:template match="non-normative-note | normative-note">
    <div class="note">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="non-normative-example | normative-example">
    <div class="example">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="disp-quote">
    <blockquote><xsl:apply-templates/></blockquote>
  </xsl:template>

  <!-- Preformat (sourcecode) -->
  <xsl:template match="preformat">
    <pre><xsl:apply-templates/></pre>
  </xsl:template>

  <!-- Bibliography -->
  <xsl:template match="ref-list">
    <div class="ref-list">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="ref">
    <p class="biblio">
      <xsl:if test="@id">
        <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="mixed-citation | element-citation">
    <span class="citation"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- std is machine-readable structured data already represented
       in mixed-citation; suppress duplicate rendering. -->
  <xsl:template match="std"/>

  <xsl:template match="std-ident">
    <span class="std-ident"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- Permissions -->
  <xsl:template match="permissions">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="copyright-statement">
    <p class="copyright"><xsl:apply-templates/></p>
  </xsl:template>

  <!-- Catch-all: pass through text and unrecognized elements -->
  <xsl:template match="text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
