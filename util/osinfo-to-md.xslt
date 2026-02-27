<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="date exsl">

<xsl:output method="text"/>

<xsl:template name="newline">
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="/libosinfo-files">
  <xsl:variable name="eol-cutoff" select="date:seconds(date:add(date:date(), '-P1Y'))"/>
  <xsl:variable name="data">
    <xsl:for-each select="file">
      <xsl:variable name="filename" select="text()"/>
      <xsl:for-each select="document(concat('/usr/share/osinfo/os/', .))/libosinfo/os">
        <xsl:if test="not(eol-date) or date:seconds(eol-date) > $eol-cutoff">
          <os>
            <filename><xsl:value-of select="$filename"/></filename>
            <xsl:copy-of select="distro | version | short-id | name"/>
            <xsl:if test="not(distro)">
              <xsl:element name="distro">
                <xsl:text>generic </xsl:text>
                <xsl:value-of select="family"/>
                <xsl:if test="not(family)">
                  <xsl:text>unknown</xsl:text>
                </xsl:if>
              </xsl:element>
            </xsl:if>
          </os>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="data-sorted">
    <xsl:for-each select="exsl:node-set($data)/os">
      <xsl:sort select="translate(distro, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
      <xsl:sort select="version" data-type="number" order="descending"/>
      <xsl:sort select="version"/>
      <xsl:sort select="short-id"/>
      <xsl:copy-of select="."/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:apply-templates select="exsl:node-set($data-sorted)/os"/>
</xsl:template>

<xsl:template match="os">
  <xsl:if test="position() = 1 or distro != preceding-sibling::os[1]/distro">
    <xsl:text>- </xsl:text>
    <xsl:value-of select="distro"/>
    <xsl:call-template name="newline"/>
  </xsl:if>
  <xsl:text>    - `</xsl:text>
  <xsl:value-of select="short-id"/>
  <xsl:text>`: [</xsl:text>
  <xsl:value-of select="name"/>
  <xsl:text>](https://gitlab.com/libosinfo/osinfo-db/-/blob/main/data/os/</xsl:text>
  <xsl:value-of select="filename"/>
  <xsl:text>.in)</xsl:text>
  <xsl:call-template name="newline"/>
</xsl:template>

</xsl:stylesheet>
