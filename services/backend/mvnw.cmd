@echo off
setlocal

set MAVEN_PROJECTBASEDIR=%~dp0
set MAVEN_WRAPPER_JAR=%MAVEN_PROJECTBASEDIR%.mvn\wrapper\maven-wrapper.jar

if not exist "%MAVEN_WRAPPER_JAR%" (
  echo Maven Wrapper jar not found: %MAVEN_WRAPPER_JAR%
  echo Download it with the documented wrapper setup command before running this script.
  exit /b 1
)

cd /d "%MAVEN_PROJECTBASEDIR%"
java -Dmaven.multiModuleProjectDirectory=%MAVEN_PROJECTBASEDIR% -classpath "%MAVEN_WRAPPER_JAR%" org.apache.maven.wrapper.MavenWrapperMain %*
endlocal
