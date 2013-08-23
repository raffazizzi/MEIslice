<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:meifn="http://www.music-encoding.org/ns/mei/fn"
    xmlns:m="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <!-- Function to determine the closest id of an event given a timestamp and a context -->
    <!-- context: a layer of a measure -->
    <!-- ts: the timestamp -->
    
    <xsl:import href="timestamp.xsl"/>
    
    <xsl:function name="meifn:getDur" as="xs:double">
        <!-- gets numerical duration for non-numerical values of @dur -->
        <xsl:param name="dur"/>
        <xsl:choose>
            <xsl:when test="$dur = 'breve'">
                <xsl:value-of select="0.5"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="number($dur)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="meifn:id2ts">
        <xsl:param name="context"/>
        <xsl:param name="ts"/>
        <xsl:for-each select="$context">
            <xsl:variable name="base" select="preceding::m:scoredef[@meter.unit][1]/@meter.unit"/>
            <xsl:variable name="events">
                <xsl:for-each select="descendant::m:note | descendant::m:rest | descendant::m:chord">
                    <!-- Other events that should be considered? -->
                    <meifn:event>
                        <xsl:copy-of select="@xml:id"/>
                        <xsl:value-of select="1 div meifn:getDur(@dur)"/>
                    </meifn:event>
                    
                    <xsl:if test="@dots">
                        <xsl:variable name="total" select="@dots"/>
                        <xsl:variable name="dur" select="meifn:getDur(@dur)"/>
                        
                        <xsl:call-template name="add_dots">
                            <xsl:with-param name="dur" select="$dur"/>
                            <xsl:with-param name="total" select="$total"/>
                        </xsl:call-template>
                        
                    </xsl:if>
                    <xsl:if test="descendant::dot">
                        <xsl:variable name="total" select="count(descendant::dot)"/>
                        <xsl:variable name="dur" select="meifn:getDur(@dur)"/>
                        
                        <xsl:call-template name="add_dots">
                            <xsl:with-param name="dur" select="$dur"/>
                            <xsl:with-param name="total" select="$total"/>
                        </xsl:call-template>
                        
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:call-template name="get_event">
                <xsl:with-param name="events" select="$events"/>
                <xsl:with-param name="event" select="$events//meifn:event[1]"/>
                <xsl:with-param name="ts" select="$ts"/>
                <xsl:with-param name="base" select="$base"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:template name="get_event">
        <xsl:param name="events"/>
        <xsl:param name="event"/>
        <xsl:param name="ts"/>
        <xsl:param name="base"/>
        <xsl:choose>
            <xsl:when test="(sum($events//meifn:event[@xml:id=$event/@xml:id]/preceding::meifn:event) div (1 div $base))+1 = number($ts)">
                <xsl:value-of select="$event/@xml:id"/>
            </xsl:when>
            <xsl:when test="$event/following-sibling::meifn:event[1]">
                <xsl:call-template name="get_event">
                    <xsl:with-param name="events" select="$events"/>
                    <xsl:with-param name="event" select="$event/following-sibling::meifn:event[1]"/>
                    <xsl:with-param name="ts" select="$ts"/>
                    <xsl:with-param name="base" select="$base"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!--<xsl:message>
                    <xsl:text>events:</xsl:text>
                    <xsl:for-each select="$events/meifn:event">
                        <xsl:value-of select="."/>;
                    </xsl:for-each>
                </xsl:message>
                <xsl:message>base: <xsl:value-of select="$base"/>; ts: <xsl:value-of select="$ts"/>; event: <xsl:value-of select="$event/@xml:id"/></xsl:message>-->
                <xsl:value-of select="error(NotFound,'Error: xml:id corresponding to given timestamp not found.')"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- test: -->
    <!--<xsl:template match="/">
        <xsl:value-of select="meifn:id2ts(//m:score[1]/m:section[1]/m:measure[7]/m:staff[1]/m:layer[1], 4)"/>
    </xsl:template>-->
    
</xsl:stylesheet>