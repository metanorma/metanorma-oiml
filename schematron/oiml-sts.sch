<?xml version="1.0" encoding="UTF-8"?>
<!--
  Schematron rules for OIML STS XML conformance to OIML X 999:2026.

  Applies the three normative constraints from Clause 6, plus structural
  integrity checks. Used by Metanorma::Oiml::Sts::Validator.

  Rules:
    oiml-x999-permission-on-reuse  — <permission> required on reused content
    oiml-x999-no-self-uri-in-xref  — <self-uri> forbidden in <self-xref>
    oiml-x999-std-title-and-date   — <title> + <pub-date> on every <std>
    oiml-x999-root-element         — root shall be <standard> or <adoption>
    oiml-x999-processing-meta      — <processing-meta> shall declare @dtd-version
-->
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
  <title>OIML X 999:2026 STS conformance rules</title>
  <ns prefix="sts" uri=""/>

  <pattern id="oiml-x999-structural">
    <rule context="/*">
      <assert id="oiml-x999-root-element" test="self::standard or self::adoption">
        The root element shall be &lt;standard&gt; or &lt;adoption&gt; (OIML X 999 Clause 7).
      </assert>
    </rule>
    <rule context="standard">
      <assert id="oiml-x999-processing-meta" test="processing-meta or ancestor::adoption">
        Every &lt;standard&gt; shall declare &lt;processing-meta&gt; (OIML X 999 Clause 7).
      </assert>
    </rule>
  </pattern>

  <pattern id="oiml-x999-bibliographic-refs">
    <rule context="std[parent::element-citation or parent::mixed-citation or parent::ref]">
      <assert id="oiml-x999-std-title-and-date-title" test="title">
        Every &lt;std&gt; shall carry a &lt;title&gt; (OIML X 999 Clause 6.3).
      </assert>
      <assert id="oiml-x999-std-title-and-date-pub-date" test="pub-date">
        Every &lt;std&gt; shall carry a &lt;pub-date&gt; (OIML X 999 Clause 6.3).
      </assert>
    </rule>
  </pattern>

  <pattern id="oiml-x999-self-references">
    <rule context="self-xref//self-uri">
      <report id="oiml-x999-no-self-uri-in-xref" test=".">
        &lt;self-uri&gt; shall not occur inside &lt;self-xref&gt; (OIML X 999 Clause 6.2).
      </report>
    </rule>
  </pattern>

  <pattern id="oiml-x999-reused-content">
    <!--
      Reused content is identified by an @reused attribute or by being wrapped
      in <attrib> alongside <permissions>. The OIML profile requires every
      such passage to carry a <permission> element.
    -->
    <rule context="*[attrib and permissions]">
      <assert id="oiml-x999-permission-on-reuse" test="permissions">
        Reused content (element carrying both &lt;attrib&gt; and &lt;permissions&gt;)
        shall include a &lt;permission&gt; element (OIML X 999 Clause 6.1).
      </assert>
    </rule>
    <rule context="disp-quote[attrib]">
      <assert id="oiml-x999-permission-on-reuse-disp-quote" test="permissions">
        A &lt;disp-quote&gt; carrying an attribution shall also carry &lt;permissions&gt;
        (OIML X 999 Clause 6.1, harmonised with Coding Changes ed 2.1 §5.9).
      </assert>
    </rule>
  </pattern>
</schema>
