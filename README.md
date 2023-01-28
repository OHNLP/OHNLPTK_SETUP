# OHNLP Toolkit Environment Setup
Installation and Preparation Scripts for setting up OHNLP Toolkit configured for an example PASC/RECOVER NLP task
## System Requirements and Recommendations
* Java 9-11
* Unix-Based System 
    * `unzip` must be installed (e.g. via `apt-get install zip unzip`)
## Installation Instructions
1. Clone this repository via `git clone https://www.github.com/OHNLP/OHNLPTK_RECOVER.git` into an empty directory
2. Execute `./install_and_update_ohnlptk_recover.sh`
3. Once installation is complete, navigate to the created `OHNLPTK_RECOVER` directory
4. Edit `configs/[run_nlp]_[ohdsi_cdm]_[ohdsi_cdm].json` lines 5-17 and lines 36-56 to reflect your data warehouse settings
## Instructions for Use
**For a Local Run:** Run `run_pipeline_local.sh`. You will be prompted for the configuration to use. Alternatively, run `run_pipeline_local.sh your_config_name.json` for non-interactive execution

**For other environments:** Executed `package_modules_and_configs.sh` and edit the `run_pipeline_###` appropriate to your environment and replace declared variables as appropriate.
