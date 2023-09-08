echo off
mode con:cols=100 lines=20
color 0B
chcp 65001
cls
set "_cd=%~dp0"
title Pick node for Nine Chronicles!
:home
cls
color 0B
echo.=====
echo.STT	Node saved
"%_cd%\jq-win64.exe" -r "[.RemoteNodeList|.[] | split(\",\") | .[0]]|range(0, length) as $index |\"\($index + 1)\t\(.[$index])\"" "%appdata%\Nine Chronicles\config.json"
echo.
echo.[1] Use random node (Normal)
echo.[2] Pick and use only one node
choice /c 12 /n /m "Enter number from keyboard: "
if %errorlevel% equ 1 (set _only=No)
if %errorlevel% equ 2 (set _only=Yes)

rem Delete %appdata%\Nine Chronicles\config.json
del /f "%appdata%\Nine Chronicles\config.json"
rem Download new config.json
curl https://download.nine-chronicles.com/9c-launcher-config.json --insecure --silent > "%appdata%\Nine Chronicles\config.json"

if not "%_only%" == "Yes" (goto :skip)

rem Create a temporary archive folder
Set /a _rand=(%RANDOM%*(10000-1+1)/32768)+1
set "_folder=%_cd%\temp\%_rand%"
if not exist "%_folder%" (md "%_folder%")
rem Receive data from 9capi
curl https://api.9capi.com/rpc --insecure --silent > "%_folder%\allRPC.json"
rem Number of nodes is available
"%_cd%\jq-win64.exe" "length" "%_folder%\allRPC.json" > "%_folder%\_lenghtRPC.txt"
set /p _lenghtRPC=<"%_folder%\_lenghtRPC.txt"
set /a _lenghtRPC=%_lenghtRPC%
:reDisplay
cls
color 0B
echo ==========
echo Pick node
echo.
echo.STT	Active	Name            	Diff	Response	RPC           	Users
set /a _count=0
rem Display all node
"%_cd%\jq-win64.exe" -r "(range(0, length) | .+1) as $index |[$index, .[$index - 1].active, (.[$index - 1].name + \"                \")[0:16], (.[$index - 1].difference|tostring+ \"  \")[0:2], (.[$index - 1].response_time_seconds|tostring+ \"        \")[0:8], (.[$index - 1].rpcaddress)[0:13], (.[$index - 1].users|tostring+\"     \")[0:5]] | @tsv" "%_folder%\allRPC.json"
set "_pick="
set /p _pick="Pick one [1 - %_lenghtRPC%]: "
if [%_pick%] == [] (echo Error 1: No import yet, try again ... & color 4F & timeout 3 >nul & goto :reDisplay)
set "var="&for /f "delims=0123456789" %%i in ("%_pick%") do set var=%%i
if defined var (echo Error 2: Not number, try again ... & color 4F & timeout 3 >nul & goto :reDisplay)
if %_pick% gtr %_lenghtRPC% (echo Error 3: The value exceeds [%_lenghtRPC%], try again ... & color 4F & timeout 3 >nul & goto :reDisplay)
"%_cd%\jq-win64.exe" -r ".[%_pick%-1]|.rpcaddress" %_folder%\allRPC.json > "%_folder%\_node.txt"
set "_node="
set /p _node=<"%_folder%\_node.txt"
copy "%appdata%\Nine Chronicles\config.json" "config.json">nul
type "config.json" | "%_cd%\jq-win64.exe" ".RemoteNodeList = [\"%_node%,80,31238\"]" > "%appdata%\Nine Chronicles\config.json"
attrib +r "%appdata%\Nine Chronicles\config.json"
rd /s /q "%_folder%"
:skip
timeout 3 > nul
goto :home