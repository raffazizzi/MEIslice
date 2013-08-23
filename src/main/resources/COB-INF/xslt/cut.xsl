<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs xd m"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:m="http://www.music-encoding.org/ns/mei"
    xmlns:meifn="http://www.music-encoding.org/ns/mei/fn" 
    xmlns:xmg="http://www.cch.kcl.ac.uk/xmod/global/1.0"
    version="2.0">
   
    <xsl:import href="id2ts.xsl"/>
    
    <xsl:param name="startm"/>
    <xsl:param name="endm"/>
    
    <!-- Gets a range of MEI measures -->
    <!-- Author: Raffaele Viglianti -->
    
    <xsl:template name="getKey">
        <xsl:param name="sig"/>
        <xsl:variable name="fifths.keys" select="('C', 'G', 'D', 'A', 'E', 'B', 'F', 'D', 'A',
            'E', 'B', 'F')"/>
        <xsl:variable name="fifths.accid" select="('', '', '' ,'', '', '', 's', 'f', 'f',
            'f', 'f', '')"/>
        <xsl:choose>
            <xsl:when test="ends-with(normalize-space($sig), 's')">
                <meifn:key><xsl:value-of select="$fifths.keys[number(substring-before($sig, 's'))+1]"/></meifn:key>
                <meifn:accid><xsl:value-of select="$fifths.accid[number(substring-before($sig, 's'))+1]"/></meifn:accid>
            </xsl:when>
            <xsl:when test="ends-with(normalize-space($sig), 'f')">
                <meifn:key><xsl:value-of select="$fifths.keys[last() - (number(substring-before($sig, 'f'))-1)]"/></meifn:key>
                <meifn:accid><xsl:value-of select="$fifths.accid[last() - (number(substring-before($sig, 'f'))-1)]"/></meifn:accid>
            </xsl:when>
            <xsl:otherwise>
                <meifn:key>C</meifn:key>
                <meifn:accid/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@*|node()[not(self::*)]" mode="meiNS">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="meiNS"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*" mode="meiNS">
        <xsl:element name="mei:{local-name()}" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:sequence select="@*"/>
            <xsl:apply-templates mode="meiNS"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="/">
        <xsl:apply-templates select="//m:score" mode="meiNS"/>
    </xsl:template>
    
    <xsl:template match="m:score" mode="meiNS">
        <xsl:element name="mei:{local-name()}" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:sequence select="@* except @xml:id"/>
            <xsl:attribute name="id">meiScore</xsl:attribute>
            <xsl:apply-templates mode="meiNS"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="m:score/m:scoredef" mode="meiNS">
        <!-- If there's a change in the section of the first measure, update the initial scoredef -->
        <xsl:choose>
            <xsl:when test="//m:measure[@n=$startm]/preceding::m:scoredef[parent::m:section][1]">
                <xsl:element name="mei:{name()}" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:sequence select="@* except @xml:id"/>
                    <xsl:sequence select="//m:measure[@n=$startm]/preceding::m:scoredef[parent::m:section][1]/@*"/>
                    <xsl:for-each select="*">
                        <xsl:choose>
                            <xsl:when test="self::m:staffgrp">
                                <xsl:element name="mei:{name()}" namespace="http://www.music-encoding.org/ns/mei">
                                    <xsl:sequence select="@*"/>
                                    <xsl:for-each select="*">
                                        <xsl:choose>
                                            <xsl:when test="self::m:staffdef">
                                                <xsl:call-template name="staffdef">
                                                    <xsl:with-param name="change" select="true()"/>
                                                </xsl:call-template>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:apply-templates mode="meiNS" select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </xsl:element>
                                
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="meiNS" select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="mei:{name()}" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:sequence select="@* except @xml:id"/>
                    <xsl:apply-templates mode="meiNS"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="m:section | m:ending" mode="meiNS">
        <xsl:choose>
            <xsl:when test="descendant::m:measure[@n=$startm or @n=$endm or (number(@n)&gt;number($startm) and number(@n)&lt;number($endm)) or (number(substring-before(@n, 'a'))&gt;=number($startm) and number(substring-before(@n, 'a'))&lt;=number($endm))]">
                <xsl:element name="mei:{name()}" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:sequence select="@*"/>
                    <xsl:apply-templates mode="meiNS"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="m:staffdef" name="staffdef" mode="meiNS">
        <xsl:param name="change" select="false()"/>
        <!--<xsl:message><xsl:value-of select="$change"/></xsl:message>-->
        <xsl:element name="mei:{name()}" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:sequence select="ancestor::m:scoredef/@* except (@xml:id, @key.sig)"/>
            <xsl:sequence select="@* except @clef.shape"/>
            <xsl:if test="$change">
                <xsl:sequence select="//m:measure[@n=$startm]/preceding::m:scoredef[parent::m:section][1]/@*"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@clef.shape != 'C' or (@clef.shape='C' and @clef.line!='4')">
                    <xsl:sequence select="@clef.shape"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="clef.shape">F</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <!-- If key info is missing, determine closest major key --> 
            <xsl:if test="not(@key.pname)">
                <xsl:variable name="key">
                    <xsl:call-template name="getKey">
                        <xsl:with-param name="sig" select="@key.sig"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:attribute name="key.pname">
                    <xsl:value-of select="$key/meifn:key"/>
                </xsl:attribute>
                <xsl:if test="$key/meifn:accid!=''">
                    <xsl:attribute name="key.accid">
                        <xsl:value-of select="$key/meifn:accid"/>
                    </xsl:attribute>
                </xsl:if>
            </xsl:if>
            <xsl:apply-templates mode="meiNS"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="m:measure" mode="meiNS">
        <xsl:choose>
            <xsl:when test="@n=$startm or @n=$endm or (number(@n)&gt;number($startm) and number(@n)&lt;number($endm)) or (number(substring-before(@n, 'a'))&gt;=number($startm) and number(substring-before(@n, 'a'))&lt;=number($endm))">
                <xsl:element name="mei:{name()}" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:sequence select="@*"/>
                    <xsl:apply-templates mode="meiNS"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- This template deals with several aspects within note -->
    <!-- only lyrics for now -->
    <xsl:template match="m:note" mode="meiNS">
        <xsl:element name="mei:note" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:sequence select="@*"/>
            <xsl:if test="not(descendant::m:syl) and preceding::m:note[ancestor::m:staff[@n=current()/ancestor::m:staff/@n]][descendant::m:syl][1]/descendant::m:syl[@wordpos='i' or @wordpos='m']">
                <xsl:element name="mei:syl" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="wordpos">m</xsl:attribute>
                    <xsl:attribute name="con">d</xsl:attribute>
                </xsl:element>
            </xsl:if>
            <xsl:apply-templates mode="meiNS"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="m:dir" mode="meiNS">
        <xsl:element name="mei:dir" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:sequence select="@*"/>
            <xsl:attribute name="startid">
                <xsl:choose>
                    <xsl:when test="@layer">
                        <xsl:value-of select="meifn:id2ts(ancestor::m:measure//m:staff[@n=current()/@staff]/m:layer[@n=current()/@layer], @tstamp)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="meifn:id2ts(ancestor::m:measure//m:staff[@n=current()/@staff]/m:layer[@n='1'], @tstamp)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates mode="meiNS"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="m:space" mode="meiNS">
        <!-- This should eventually be handled in MEItoVexFlow -->
    </xsl:template>
    
    <!-- SPECIFIC TO DUCHEMIN -->
    <!-- get very last note and make it longa -->
    <!--<xsl:template match="m:note[not(following-sibling::m:note)][ancestor::m:measure[not(following::m:measure)]]" mode="meiNS" priority="1">
        <xsl:element name="mei:note" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:sequence select="@* except @dur"/>
            <xsl:attribute name="dur" select="'breve'"/>
            <xsl:if test="not(descendant::m:syl) and preceding::m:note[ancestor::m:staff[@n=current()/ancestor::m:staff/@n]][descendant::m:syl][1]/descendant::m:syl[@wordpos='i' or @wordpos='m']">
                <xsl:element name="mei:syl" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="wordpos">m</xsl:attribute>
                    <xsl:attribute name="con">d</xsl:attribute>
                </xsl:element>
            </xsl:if>
            <xsl:apply-templates mode="meiNS"/>
        </xsl:element>
    </xsl:template>-->
    
</xsl:stylesheet>

