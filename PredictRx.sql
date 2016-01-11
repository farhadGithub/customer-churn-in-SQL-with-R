/* 
	Description: This file creates the procedure to predict churn outcome based on the Revolution R model previously built.
	Author: farhad.ghassemi@microsoft.com
	Date: Jan 2016
*/
use [Churn]
go

set ansi_nulls on
go

set quoted_identifier on
go

if EXISTS (select * from sys.objects where type = 'P' AND name = 'PredictChurnRx')
  drop procedure TrainModelR
go


create procedure PredictChurnRx @inquery nvarchar(max)
as
begin
  declare @modelt varbinary(max) = (select top 1 model from ChurnModelRx);
  exec sp_execute_external_script @language = N'R',
                                  @script = N'
mod <- unserialize(as.raw(model));
print(summary(mod))
Scores<-rxPredict(modelObject = mod, data = InputDataSet, outData = NULL, 
          predVarNames = "Score", type = "response", writeModelVars = FALSE, overwrite = TRUE);
OutputDataSet <- data.frame(InputDataSet$UserId,InputDataSet$Tag,Scores)
str(OutputDataSet)
print(OutputDataSet)

',
                                  @input_data_1 = @inquery,
                                  @params = N'@model varbinary(max)',
                                  @model = @modelt
  with RESULT sets ((UserId bigint,
                     Tag varchar(10),    
                     Score float));
end