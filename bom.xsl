<?xml version="1.0" encoding="utf-8" ?>
<!--
 - Copyright (C) 2023-2024 ConnectorIO Sp. z o.o.
 -
 - Licensed under the Apache License, Version 2.0 (the "License");
 - you may not use this file except in compliance with the License.
 - You may obtain a copy of the License at
 -
 -     http://www.apache.org/licenses/LICENSE-2.0
 -
 - Unless required by applicable law or agreed to in writing, software
 - distributed under the License is distributed on an "AS IS" BASIS,
 - WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 - See the License for the specific language governing permissions and
 - limitations under the License.
 -
 - SPDX-License-Identifier: Apache-2.0
 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:pom="http://maven.apache.org/POM/4.0.0" exclude-result-prefixes="pom">

  <!--
  This basic transformation set allows to generate pom file stripped of everything but dependencies.
  Dependencies themselves are moved as-is into dependency management section producing fully functional
  bill of materials POM.
  -->
  <xsl:output method="xml" encoding="utf-8" indent="yes" xslt:indent-amount="2" xmlns:xslt="http://xml.apache.org/xslt" />

  <xsl:param name="BOM_PARENT_GROUP_ID" />
  <xsl:param name="BOM_PARENT_ARTIFACT_ID" />
  <xsl:param name="BOM_VERSION" />

  <xsl:param name="VERSION" />
  <xsl:param name="RESULT_NAME" />
  <xsl:param name="RESULT_GROUP_ID" />

  <xsl:param name="RESULT_FORCE_SCOPE" />

  <xsl:param name="PWD" />

  <xsl:variable name="reactor" select="document(concat($PWD, '/openhab-reactor.xml'))" />

  <xsl:template match="/">
    <!--
    inject header comment to generated file, to keep it consistent and ready for future copyright checks
    -->
    <xsl:text>&#10;</xsl:text>
    <xsl:comment>
 - Copyright (C) 2023-2024 ConnectorIO Sp. z o.o.
 -
 - Licensed under the Apache License, Version 2.0 (the "License");
 - you may not use this file except in compliance with the License.
 - You may obtain a copy of the License at
 -
 -     http://www.apache.org/licenses/LICENSE-2.0
 -
 - Unless required by applicable law or agreed to in writing, software
 - distributed under the License is distributed on an "AS IS" BASIS,
 - WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 - See the License for the specific language governing permissions and
 - limitations under the License.
 -
 - SPDX-License-Identifier: Apache-2.0
</xsl:comment>
    <xsl:text>&#10;</xsl:text>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- override parent coordinates -->
  <xsl:template match="pom:parent">
    <xsl:element name="parent" namespace="{namespace-uri()}">
      <xsl:element name="groupId" namespace="{namespace-uri()}">
        <xsl:value-of select="$BOM_PARENT_GROUP_ID" />
      </xsl:element>
      <xsl:element name="artifactId" namespace="{namespace-uri()}">
        <xsl:value-of select="$BOM_PARENT_ARTIFACT_ID" />
      </xsl:element>
      <xsl:element name="version" namespace="{namespace-uri()}">
        <xsl:value-of select="$BOM_VERSION" />
      </xsl:element>
      <xsl:element name="relativePath" namespace="{namespace-uri()}">
        <xsl:text>../pom.xml</xsl:text>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!-- inject custom groupId -->
  <xsl:template match="pom:project/pom:artifactId">
    <xsl:element name="groupId" namespace="{namespace-uri()}">
      <xsl:value-of select="$RESULT_GROUP_ID" />
    </xsl:element>
    <xsl:element name="artifactId" namespace="{namespace-uri()}">
      <xsl:value-of select="//pom:project/pom:artifactId" />
    </xsl:element>
  </xsl:template>

  <!-- inject custom name and description -->
  <xsl:template match="pom:project/pom:name">
    <xsl:element name="name" namespace="{namespace-uri()}">
      <xsl:value-of select="$RESULT_NAME" />
    </xsl:element>
    <xsl:if test="not(//pom:description)">
      <!-- inject basic project description -->
      <xsl:element name="description" namespace="{namespace-uri()}">
        <xsl:value-of select="concat('Generated BOM file for ', $RESULT_NAME)" />
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template match="pom:project/pom:dependencies">
    <xsl:element name="dependencyManagement" namespace="{namespace-uri()}">
      <xsl:copy>
        <xsl:if test="//pom:dependencyManagement/pom:dependencies/pom:dependency">
          <xsl:comment>Copy of dependencyManagement section</xsl:comment>
          <xsl:apply-templates select="//pom:dependencyManagement/pom:dependencies/pom:dependency"/>
          <xsl:comment>Rest of dependencies</xsl:comment>
        </xsl:if>
        <xsl:apply-templates select="pom:dependency"/>
      </xsl:copy>
    </xsl:element>
  </xsl:template>


  <xsl:template match="pom:dependencyManagement">
  </xsl:template>
  <xsl:template match="pom:properties">
  </xsl:template>

  <xsl:template match="pom:dependency">
    <xsl:choose>
      <!--
      Process node only when version is defined, otherwise it is a dependency which comes from
      dependencyManagement of imported pom, which we import too.
      -->
      <xsl:when test="pom:version">
        <xsl:call-template name="process-dependency">
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- string-replace-all from http://geekswithblogs.net/Erik/archive/2008/04/01/120915.aspx -->
  <xsl:template name="string-replace-all">
    <xsl:param name="text" />
    <xsl:param name="replace" />
    <xsl:param name="by" />
    <xsl:choose>
      <xsl:when test="contains($text, $replace)">
        <xsl:value-of select="substring-before($text,$replace)" />
        <xsl:value-of select="$by" />
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="substring-after($text,$replace)" />
          <xsl:with-param name="replace" select="$replace" />
          <xsl:with-param name="by" select="$by" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="process-dependency">
    <xsl:element name="dependency" namespace="{namespace-uri()}">
      <xsl:copy-of select="./pom:groupId" />
      <xsl:copy-of select="./pom:artifactId" />

      <xsl:variable name="pomVersion" select="pom:version" />
      <xsl:choose>
        <!-- project.version placeholder -->
        <xsl:when test="contains(pom:version, '${project.version}')">
          <xsl:element name="version" namespace="{namespace-uri()}">
            <xsl:call-template name="string-replace-all">
              <xsl:with-param name="text" select="pom:version"/>
              <xsl:with-param name="replace" select="'${project.version}'"/>
              <xsl:with-param name="by" select="$VERSION"/>
            </xsl:call-template>
          </xsl:element>
        </xsl:when>
        <!-- another placeholder -->
        <xsl:when test="starts-with($pomVersion, '${')">
          <xsl:variable name="length" select="string-length($pomVersion)"/>
          <xsl:variable name="placeholder" select="substring($pomVersion, 3, ($length - 3))" />
          <!--
          Resolve placeholder value by looking up for <$placeholder> tag.
          First stage looks at local document, if it yields empty result, then reactor pom is checked.
          There are several placeholders defined there ie. ${xtext.version} which can be feed this way.
          -->
          <xsl:variable name="placeholderValue">
            <xsl:choose>
              <xsl:when test="//*[local-name()=$placeholder]">
                <xsl:value-of select="//*[local-name()=$placeholder]" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$reactor//*[local-name()=$placeholder]" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:choose>
            <xsl:when test="$placeholderValue != ''">
              <!-- Use resolved placeholder value if its found -->
              <xsl:element name="version" namespace="{namespace-uri()}">
                <xsl:value-of select="$placeholderValue" />
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <!-- Stick with source value, placeholder is not resolved -->
              <xsl:element name="version" namespace="{namespace-uri()}">
                <xsl:value-of select="$pomVersion" />
              </xsl:element>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$pomVersion != ''">
          <xsl:element name="version" namespace="{namespace-uri()}">
            <xsl:value-of select="$pomVersion" />
          </xsl:element>
        </xsl:when>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="$RESULT_FORCE_SCOPE != '' and $RESULT_FORCE_SCOPE != 'none'">
          <xsl:element name="scope" namespace="{namespace-uri()}">
            <xsl:value-of select="$RESULT_FORCE_SCOPE" />
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="./pom:scope">
            <xsl:copy-of select="./pom:scope" />
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="./pom:type">
        <xsl:copy-of select="./pom:type" />
      </xsl:if>
      <xsl:if test="./pom:exclusions">
        <xsl:apply-templates select="./pom:exclusions" />
      </xsl:if>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>