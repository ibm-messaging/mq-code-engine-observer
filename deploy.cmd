@echo off
@REM © Copyright IBM Corporation 2024
@REM 
@REM Licensed under the Apache License, Version 2.0 (the "License");
@REM you may not use this file except in compliance with the License.
@REM You may obtain a copy of the License at
@REM 
@REM http://www.apache.org/licenses/LICENSE-2.0
@REM 
@REM Unless required by applicable law or agreed to in writing, software
@REM distributed under the License is distributed on an "AS IS" BASIS,
@REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@REM See the License for the specific language governing permissions and
@REM limitations under the License.

set BASEDIR=%__CD__%

set CE_PROJECT_SETTING="mq-observer"

set OBSERVER_APP_NAME="ce-mq-observer"
set OBSERVER_SECRETS_NAME="observer-secrets"
set OBSERVER_CONFIG_NAME="observer-config"

set CONSUMER_JOB_NAME="ce-mq-consumer"
set CONSUMER_SECRETS_NAME="consumer-secrets"

set COS_KEY_SETTING=""
set RESOURCES_DIR="observer/resources"
set SEED_REGISTRATION_DATA=seeddata

set NOTIFY_INTERVAL_SETTING=""

echo "Starting deployment of IBM MQ Observer to Code Engine"
echo Base directory is %BASEDIR%

call :projectcheck
call :clean

if "%~1"=="clean" (
    echo Exiting as only clean selected
    goto complete
)

call :check
if %ERRORLEVEL% NEQ 0 (
    echo Environment settings check failed, exiting 
    goto complete
)

call :createconfig
call :createjobdefinition
call :createapp


echo "Deployment completed"
goto complete




:projectcheck
    echo "Checking Code Engine project"

    if defined CE_PROJECT (
        set CE_PROJECT_SETTING=%CE_PROJECT%
    ) 
    echo Code Engine project is %CE_PROJECT_SETTING%
    ibmcloud ce project select --name %CE_PROJECT_SETTING%
    if %ERRORLEVEL% NEQ 0 (
        echo Creating project %CE_PROJECT_SETTING%
        ibmcloud ce project create --name %CE_PROJECT_SETTING%
    )

    echo "Check of Code Engine project completed"
exit /b 0

:clean
    echo Cleaning previous deployment, if any

    ibmcloud ce secret delete --name %OBSERVER_SECRETS_NAME% -f --ignore-not-found
    ibmcloud ce configmap delete --name %OBSERVER_CONFIG_NAME% -f --ignore-not-found
    ibmcloud ce app delete --name %OBSERVER_APP_NAME% -f --ignore-not-found

    ibmcloud ce secret delete --name %CONSUMER_SECRETS_NAME% -f --ignore-not-found
    ibmcloud ce job delete --name %CONSUMER_JOB_NAME% -f --ignore-not-found

    echo Clean completed
exit /b 0

:check
    echo Checking environment variables
    set is_good=1

    if not defined ADMIN_USER (
        echo "[ERROR] ADMIN_USER for MQ mandatory env var is not defined"
        set is_good=0
    ) 

    if not defined ADMIN_PASSWORD (
        echo "[ERROR] ADMIN_PASSWORD for MQ mandatory env var is not defined"
        set is_good=0
    ) 

    if not defined APP_USER (
        echo "[ERROR] APP_USER for MQ mandatory env var is not defined"
        set is_good=0
    ) 

    if not defined APP_PASSWORD (
        echo "[ERROR] APP_PASSWORD for MQ mandatory env var is not defined"
        set is_good=0
    ) 

    if not defined ce_apikey (
        echo "[ERROR] ce_apikey for MQ mandatory env var is not defined"
        set is_good=0
    ) 

    if %is_good% EQU 0 (
        exit /b 10
    )

    if defined cos_apikey (
        set COS_KEY_SETTING=--from-literal cos_apikey=%cos_apikey%
    ) 

    if defined NOTIFY_INTERVAL (
        set NOTIFY_INTERVAL_SETTING=--from-literal NOTIFY_INTERVAL=%NOTIFY_INTERVAL%
    ) 

    echo envrionment check is complete
exit /b 0

:createconfig
    echo Creating deployment assets

    echo Creating secret %OBSERVER_SECRETS_NAME%
    ibmcloud ce secret create --name %OBSERVER_SECRETS_NAME% ^
        --from-literal ADMIN_USER=%ADMIN_USER% ^
        --from-literal ADMIN_PASSWORD=%ADMIN_PASSWORD% ^
        --from-literal ce_apikey=%ce_apikey% ^
        %COS_KEY_SETTING%

    echo Creating configmap %OBSERVER_CONFIG_NAME%
    ibmcloud ce configmap create --name %OBSERVER_CONFIG_NAME% ^
        --from-file %BASEDIR%/%RESOURCES_DIR%/%SEED_REGISTRATION_DATA% ^
        %NOTIFY_INTERVAL_SETTING%

    echo Creating secret %CONSUMER_SECRETS_NAME%
    ibmcloud ce secret create --name %CONSUMER_SECRETS_NAME% ^
        --from-literal APP_USER=%APP_USER% ^
        --from-literal APP_PASSWORD=%APP_PASSWORD% 

exit /b 0

:createjobdefinition
    echo Creating consumer job definition %CONSUMER_JOB_NAME%

    ibmcloud ce job create --name %CONSUMER_JOB_NAME% ^
        --build-source %BASEDIR% ^
        --build-dockerfile Dockerfile.consumer ^
        --env-from-secret %CONSUMER_SECRETS_NAME%
exit /b 0

:createapp
    echo Creating observer application %OBSERVER_APP_NAME%

    ibmcloud ce app create --name %OBSERVER_APP_NAME% ^
        --build-source %BASEDIR% ^
        --build-dockerfile Dockerfile ^
        --env-from-secret %OBSERVER_SECRETS_NAME% ^
        --env-from-configmap %OBSERVER_CONFIG_NAME% ^
        --min-scale=1 --max-scale=1 --wait
exit /b 0



:complete
 