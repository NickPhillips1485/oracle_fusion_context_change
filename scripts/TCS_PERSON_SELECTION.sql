/*************************************************

Name: TCS_PERSON_SELECTION
type: Compensation Person Selection
Date: today 
Dev:  Tilak
Requirement: Select the Person whose total salary of all the Job is > 50K as of effective date

*************************************************/

/* Declare DBIs */ 

DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_START_DATE is   '1900/01/01' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_END_DATE is   '1900/01/01' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_ASSIGNMENT_ID is -1 
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_STATUS_TYPE is ' '
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_LATEST_CHANGE is ' '

DEFAULT FOR CMP_ASSIGNMENT_SALARY_ANNUAL_AMOUNT is 0

l_temp =  ESS_LOG_WRITE('Entering  TCS_PERSON_SELECTION ' )
RETVAL = 'Y' 
SALARY = 0

l_person_id = get_context(PERSON_ID, -1 )
l_asg_id    = get_context(HR_ASSIGNMENT_ID, -1)
l_date      = get_context(EFFECTIVE_DATE, '1900/01/01' (date) )

l_temp =  ESS_LOG_WRITE('person id  ' + TO_CHAR(l_person_id) )
l_temp =  ESS_LOG_WRITE('Asg id  ' + TO_CHAR(l_asg_id) )
l_temp =  ESS_LOG_WRITE('Eff Date  ' + TO_CHAR(l_date) )

/* Loop through the person assignment */ 

count = PER_HIST_ASG_ASSIGNMENT_ID.count 
l_temp =  ESS_LOG_WRITE('Count of asg  ' + TO_CHAR(count) )
index = PER_HIST_ASG_ASSIGNMENT_ID.FIRST(-1)

While (PER_HIST_ASG_ASSIGNMENT_ID.EXISTS(index))

Loop (

   l_asg =    PER_HIST_ASG_ASSIGNMENT_ID[index]
   l_s_date = PER_HIST_ASG_EFFECTIVE_START_DATE[index] 
   l_e_date = PER_HIST_ASG_EFFECTIVE_END_DATE[index] 
   l_type   = PER_HIST_ASG_STATUS_TYPE[index]
   l_change = PER_HIST_ASG_EFFECTIVE_LATEST_CHANGE[index] 

   l_temp =  ESS_LOG_WRITE('l_asg  ' + TO_CHAR(l_asg) )  
   l_temp =  ESS_LOG_WRITE('l_s_date  ' + TO_CHAR(l_s_date) )
   l_temp =  ESS_LOG_WRITE('l_e_date  ' + TO_CHAR(l_e_date) )
   l_temp =  ESS_LOG_WRITE('l_type  ' + l_type )
   l_temp =  ESS_LOG_WRITE('l_change  ' + l_change )

   /* Validation */ 

   IF l_date >= l_s_date AND  l_date <= l_e_date THEN 
   (
      IF l_type = 'ACTIVE' and  l_change = 'Y' then 
      (
         l_temp =  ESS_LOG_WRITE('setting context for  ' + TO_CHAR(l_asg) )  
         CHANGE_CONTEXTS(HR_ASSIGNMENT_ID = l_asg)
		(
            SALARY = SALARY + CMP_ASSIGNMENT_SALARY_ANNUAL_AMOUNT
            l_temp =  ESS_LOG_WRITE('SALARY  ' + TO_CHAR(SALARY) )
       
		)

      )

   )
  index = PER_HIST_ASG_ASSIGNMENT_ID.NEXT(index, -1) 

	) 
	/* End of Loop*/

/*Calculation Section*/

IF SALARY > 50000 then 
(
      RETVAL = 'Y' 
      l_temp =  ESS_LOG_WRITE('FINAL SALARY  ' + TO_CHAR(SALARY) )
)

l_temp = ESS_LOG_WRITE('Returning  TCS_PERSON_SELECTION ' || RETVAL)

/*Return Section*/

Return RETVAL