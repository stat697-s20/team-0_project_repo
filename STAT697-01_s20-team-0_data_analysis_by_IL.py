# load objects needed from packages in the standard library
from datetime import datetime
from pathlib import Path

# load third-party SASPy package, and create a connection to a SAS kernel
from saspy import SASsession
sas = SASsession()


# define data-analysis SAS file to be executed
SAS_INPUT_FILE = 'STAT697-01_s20-team-0_data_analysis_by_IL.sas'


# get value of automatic macro variable &SYSJOBID corresponding to the SAS session
sas_job_id = sas.symget("SYSJOBID")

# if needed, created directory ./sas_output, where all output will be written
sas_output_directory_name = 'sas_output'
sas_output_directory = Path(sas_output_directory_name)
sas_output_directory.mkdir(parents=True, exist_ok=True)

# set parameters for outputing time-stamped log and results files
current_timestamp = datetime.now().strftime("%Y-%m-%dT%H-%M-%S")
sas_output_filename_stem = '%s-job_id_%s'%(current_timestamp, sas_job_id)
sas_log_file = './%s/%s.log'%(sas_output_directory_name, sas_output_filename_stem)
sas_results_file = './%s/%s.html'%(sas_output_directory_name, sas_output_filename_stem)

# read contents of data-analysis SAS file, and submit to SAS session
with open(SAS_INPUT_FILE) as fp:
    sas_submit_return_value = sas.submit(fp.read(), results='')

# write results from data-analysis SAS file execution to external file
with open(sas_results_file, 'w') as fp:
    fp.write(sas_submit_return_value['LST'])

# write log from data-analysis SAS file execution to external file
with open(sas_log_file, 'w') as fp:
    fp.write(sas_submit_return_value['LOG'])

# print successful-execution messages to stdout
print('SAS file %s executed with job id %s'%(SAS_INPUT_FILE, sas_job_id))
print('Log written to file %s'%sas_log_file)
print('Results written to file %s'%sas_results_file)
