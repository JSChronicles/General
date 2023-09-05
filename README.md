# General

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
[![Psscriptanalyzer][Psscriptanalyzer-badge]][Psscriptanalyzer-url]
[![Pester Test][Pester-Test-badge]][Pester-Test-url]


<!-- PROJECT LOGO -->
<br />
<div align="center">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">README</h3>

  <p align="center">
    <a href="https://github.com/JSChronicles/General"><strong>Explore the docs »</strong></a>
    <br />
    <a href="https://github.com/JSChronicles/General/issues/new?assignees=&labels=bug&projects=&template=bug_report.md&title=">Report Bug</a>
    ·
    <a href="https://github.com/JSChronicles/General/issues/new?assignees=&labels=enhancement&projects=&template=feature_request.md&title=">Request Feature</a>
  </p>
</div>

## Introduction
A repository of possibly helpful scripts

## Usage
Most of my scripts utilize a logger so that way you can review the logs at some point on your own time.If you don't want that then  either comment
or remove all lines that start with `$logger.`

Basically we can check if the type is currently initated and if not then we can do it via this small piece of code
```PowerShell
# This will grab the currently running script name and name the log file as such
if (!("PSLogger" -as [type])) {
    $callingSCript = ($MyInvocation.MyCommand.Name) -split ('.ps1')
    ."\\UNC\Path\Here\Logging.ps1"
    $logger = [PSLogger]::new($logPath, $callingScript)
}

# This will use "ScriptNameHere" to name the log file
if (!("PSLogger" -as [type])) {
    ."\\UNC\Path\Here\Logging.ps1"
    $logger = [PSLogger]::new($logPath, "ScriptNameHere")
}
```

<!-- MARKDOWN LINKS & IMAGES -->
[Psscriptanalyzer-badge]:hhttps://github.com/JSChronicles/General/actions/workflows/psscriptanalyzer.yaml/badge.svg?branch=main
[Psscriptanalyzer-url]:hhttps://github.com/JSChronicles/General/actions/workflows/psscriptanalyzer.yaml
[Pester-Test-badge]:hhttps://github.com/JSChronicles/General/actions/workflows/Pester.yaml/badge.svg?branch=main
[Pester-Test-url]:hhttps://github.com/JSChronicles/General/actions/workflows/Pester.yaml
