@rem Gitbox Gradle wrapper launcher for Windows
@echo off
set DIR=%~dp0
java -cp "%DIR%gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain %*
