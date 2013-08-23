<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:meifn="http://www.music-encoding.org/ns/mei/fn"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <!-- Function to determine the timestamp of an event given its id -->
    <!-- context: a layer of a measure -->
    <!-- eventid: the id of the event for which we're determining the timestamp -->
    
    <xsl:function name="meifn:timestamp">
        <xsl:param name="context"/>
        <xsl:param name="eventid"/>
        
        <!--  Given a context layer and an @xml:id of a note or rest, 
            return the timestamp of the note or rest.-->
        
        <xsl:for-each select="$context">
            <xsl:variable name="base" select="preceding::scoredef[1]/@meter.unit"/>
            <xsl:variable name="events">
                <xsl:for-each select="descendant::note | descendant::rest">
                    <!-- Other events that should be considered? -->
                    <meifn:event>
                        <xsl:if test="$eventid = @xml:id">
                            <xsl:attribute name="this">this</xsl:attribute>
                        </xsl:if>
                        <xsl:value-of select="1 div @dur"/>
                    </meifn:event>
                    
                    <xsl:if test="@dots">
                        <xsl:variable name="total" select="@dots"/>
                        <xsl:variable name="dur" select="@dur"/>
                        
                        <xsl:call-template name="add_dots">
                            <xsl:with-param name="dur" select="$dur"/>
                            <xsl:with-param name="total" select="$total"/>
                        </xsl:call-template>
                        
                    </xsl:if>
                    <xsl:if test="descendant::dot">
                        <xsl:variable name="total" select="count(descendant::dot)"/>
                        <xsl:variable name="dur" select="@dur"/>
                        
                        <xsl:call-template name="add_dots">
                            <xsl:with-param name="dur" select="$dur"/>
                            <xsl:with-param name="total" select="$total"/>
                        </xsl:call-template>
                        
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <!--DEBUG<xsl:copy-of select="$events"/>-->
            <xsl:value-of select="(sum($events//meifn:event[@this]/preceding::meifn:event) div (1 div $base))+1"/>
            
        </xsl:for-each>
    </xsl:function>
    
    <xsl:template name="add_dots">
        <xsl:param name="dur"/>
        <xsl:param name="total"/>
        
        <!--Given an event's duration and a number of dots, 
            return the value of the dots-->
        
        <meifn:event dot="extradot">
            <xsl:value-of select="1 div ($dur * 2)"/>
        </meifn:event>
        <xsl:if test="$total != 1">
            <xsl:call-template name="add_dots">
                <xsl:with-param name="dur" select="$dur * 2"/>
                <xsl:with-param name="total" select="$total - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>