<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text"/>

<xsl:template match="/domain">
  <xsl:apply-templates select="os/firmware/feature[@name = 'secure-boot']"/>
  <xsl:if test="not(os/firmware/feature[@name = 'secure-boot'])">
    <xsl:text>secure-boot=missing</xsl:text>
  </xsl:if>
  <xsl:text>,</xsl:text>
  <xsl:apply-templates select="os/firmware/feature[@name = 'enrolled-keys']"/>
  <xsl:if test="not(os/firmware/feature[@name = 'enrolled-keys'])">
    <xsl:text>enrolled-keys=missing</xsl:text>
  </xsl:if>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="feature">
  <xsl:value-of select="@name"/>
  <xsl:text>=</xsl:text>
  <xsl:value-of select="@enabled"/>
  <xsl:if test="not(@enabled)">
    <xsl:text>unset</xsl:text>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
