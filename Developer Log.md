## oracle_fusion_context change

As I'll soon be starting a new role as an Oracle Fusion Payroll Consultant, I wanted to practice some of the required skills, especially in relation to Oracle's Fast Formula programming language. In this mini-project I'll be learning how to use the CHANGE_CONTEXTS functions in Fast Formula in order to change the context values within a formula block. 

### Scenario

A formula of type 'Compensation Person Selection' is required that will be used as a parameter for processes such as 'Generate Statements.' It checks against the 
eligibility criteria that an employee must earn 50k across multiple assignments. A loop is used to build a cumulative salary value. 

Whilst many of the DBIs involved are array DBIs which share the same context, the critical DBI for the annual salary amount is a single-value DBI (it's from the CMP route
whereas the array DBIs are from PER route), meaning each assignment will have to be manually looped using the CHANGE_CONTEXTS function in order for the formula to retrieve the right salary for each. 

## Formula Review

See scripts folder for full versions of formulas. 

### Note -
If I was to further refine the formula, rather than initializing Salary as 0, it probably would have been better to use the NOT DEFAULTED / DEFAULTED method. I think this is because if `SALARY` already has a value (for example, passed from another formula), setting `SALARY = 0` wipes it out. Using `NOT DEFAULTED`, we only set it to `0` if it hasn’t already been assigned a value

 After identifying the DBIs, they are initialized - note that the first five are arrays and the sixth is a single value DBI, hence the slightly different syntax for defaulting:

```
/* Declare DBIs */ 

DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_START_DATE is   '1900/01/01' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_END_DATE is   '1900/01/01' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_ASSIGNMENT_ID is -1 
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_STATUS_TYPE is ' '
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_LATEST_CHANGE is ' '

DEFAULT FOR CMP_ASSIGNMENT_SALARY_ANNUAL_AMOUNT is 0
```

Then initialize the local variables (I should have prefixed them all with l_):

```
l_temp =  ESS_LOG_WRITE('Entering  TCS_PERSON_SELECTION ' )
RETVAL = 'Y' 
SALARY = 0
```

Strictly speaking this next bit isn't 100% necessary - it's just about pulling out and printing the context values (for PERSON_ID, ASSIGNMENT_ID and EFFECTIVE DATE) before we start looping. 

```
l_person_id = get_context(PERSON_ID, -1 )
l_asg_id    = get_context(HR_ASSIGNMENT_ID, -1)
l_date      = get_context(EFFECTIVE_DATE, '1900/01/01' (date) )

l_temp =  ESS_LOG_WRITE('person id  ' + TO_CHAR(l_person_id) )
l_temp =  ESS_LOG_WRITE('Asg id  ' + TO_CHAR(l_asg_id) )
l_temp =  ESS_LOG_WRITE('Eff Date  ' + TO_CHAR(l_date) )
```
### Breakdown of Loop Section

Before starting the looping, count and print the number of assignments in the array DBI that holds the assignment IDs. The count is assigned to a variable called count.

```
count = PER_HIST_ASG_ASSIGNMENT_ID.count 
l_temp =  ESS_LOG_WRITE('Count of asg  ' + TO_CHAR(count) )
```

Then create a variable called index which holds the first variable of the array (derived from the FIRST function).

```
index = PER_HIST_ASG_ASSIGNMENT_ID.FIRST(-1)
```

Next, setup the WHILE condition for the loop. Embedded within the WHILE condition is the EXISTS function which uses the index variable created above as its argument. We saw that the index variable was set to the FIRST element of the array.

In other words, WHILE the variable called index exists, keep looping. You might find this confusing because index is currently set as the first element in the array, but at the end of the loop we'll be using the next NEXT function to increment the value (effectively it's our counter function). The line where index was set as FIRST was before the loop started, that only happened once. The element held by the variable index gets updated each time we run the loop, it doesn't stay at FIRST.

```
While (PER_HIST_ASG_ASSIGNMENT_ID.EXISTS(index))
```

Every time the loop runs, we want to see what variables were extracted for index (remember index is the variable holding the assignment number for that iteration of the loop) for the other DBI array variables we are interested in. Using the below snippet, for each assignment we're getting the start date, end date, type and last change date for the assignment held in index. Index is square bracketed because that's the syntax for when we're using collections (array-like DBI variables) in Fast Formula to retrieve values for a specific indexed entry.

Note how the values picked up are assigned to variables. 

The results are then printed. 

```
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
```

Next up is the validation section. Here we'll put the values we've picked up from the loop through a funnel of two conditional statements. This is good practice for ensuring that before you're only bringing valid values into the formula.

```
 IF l_date >= l_s_date AND  l_date <= l_e_date THEN 
   (
      IF l_type = 'ACTIVE' and  l_change = 'Y' then 
```

For assignments that meet both IF conditions (i.e. exist with a status of ACTIVE between the start and end date variables), we now need to use the CHANGE_CONTEXTS function.

Why?
You might wonder why we need to use CHANGE_CONTEXTS if the whole point of the loop is to iterate through the assignments. The answer is that we can only loop through array DBIs (or array input values, array variables etc.). Note from the section where we declare our DBIs that one of them is not an array:

```
DEFAULT FOR CMP_ASSIGNMENT_SALARY_ANNUAL_AMOUNT is 0
```

So even though we can use the non-array DBIs (like `CMP_ASSIGNMENT_SALARY_ANNUAL_AMOUNT`), only the value for the primary assignment will be retrieved unless the context is explicitly changed.

If an employee has multiple assignments, and we want to calculate salary for each one separately, we must **switch context** to the correct assignment.

Then we pull the value from the salary DBI `CMP_ASSIGNMENT_SALARY_ANNUAL_AMOUNT` for that assignment. 

We're building a cumulative value for the SALARY variable by adding to it as we go through each iteration of the loop. Remember our goal here is to see if that running total exceeds 50k.

```
      IF l_type = 'ACTIVE' and  l_change = 'Y' then 
      (
         l_temp =  ESS_LOG_WRITE('setting context for  ' + TO_CHAR(l_asg) )  
         CHANGE_CONTEXTS(HR_ASSIGNMENT_ID = l_asg)
		(
            SALARY = SALARY + CMP_ASSIGNMENT_SALARY_ANNUAL_AMOUNT
            l_temp =  ESS_LOG_WRITE('SALARY  ' + TO_CHAR(SALARY) )
      
```

...before iterating through the loop to the next assignment using the NEXT function. Once that's done, we end the loop and prepare to move back to the start (the loop will keep running until the EXISTS function at the start no longer resolves as True.

```
index = PER_HIST_ASG_ASSIGNMENT_ID.NEXT(index, -1) 

	) 
	/* End of Loop*/
```

When the loop is done, we check whether the cumulative total exceeds 50k and print the result.

The formula type 'Compensation Person Selection' requires a Return Value of 'Y' or 'N', hence the RETVAL variable (the sample formula in the guidance uses l_selection).

The cumulative salary value is printed.

```
/*Calculation Section*/

IF SALARY > 50000 then 
(
      RETVAL = 'Y' 
      l_temp =  ESS_LOG_WRITE('FINAL SALARY  ' + TO_CHAR(SALARY) )
)
```

As is the RETVAL amount being passed to the Return Statement:

```
l_temp = ESS_LOG_WRITE('Returning  TCS_PERSON_SELECTION ' || RETVAL)

/*Return Section*/

Return RETVAL
```
### Appendix - Why -1 as the default for arrays (rather than 0 or 1)?

1. **Sparse Collections**
    
    - Unlike Python lists (`list[-1]` for the last element), **Oracle Fast Formula collections do not always have sequential indexes**.
    - Example:
              
        `Indexes: 1, 3, 7`
        
    - There are missing indexes (e.g., **2, 4, 5, 6 don’t exist**).
    - 
2. **How `FIRST(-1)` Works**
    
    - `FIRST(-1)` **finds the first valid index, ignoring missing ones**.
    - Example:
        
        `index = PER_HIST_ASG_ASSIGNMENT_ID.FIRST(-1)`
        
        If indexes exist at `1, 3, 7`, it will **return `1` (the lowest valid index)**.
        
3. **How `NEXT(index, -1)` Works**
    
    - `NEXT(index, -1)` **finds the next valid index** after `index`, even if there are gaps.
    - Example:
        
        `index = PER_HIST_ASG_ASSIGNMENT_ID.NEXT(index, -1)`
        
        - If `index = 1`, and the next valid one is `3`, it will **skip `2` (since it doesn’t exist) and go directly to `3`**.
        - If `index = 3`, it will jump to `7`, skipping `4, 5, 6`.
4. **Why Use `-1` Instead of `1`?**
    
    - Using `1` in `NEXT(index, 1)` assumes that the next valid index is always `index + 1`, which **fails if there are gaps**.
    - `-1` **tells Oracle to safely find the next available index without assuming continuity**.

Once compiled the 'Generate Statements' process can be run, with the name of this formula used to populate the 'Person Selection Formula' field.

### Summary 

Although this exercise was supposed to just be about contexts, it also presented an opportunity to learn more about arrays, loops and routes.
The main lessons are:

- DBI selection is the critical first step in fast formula design (just like working out which tables and columns are needed is vital for SQL query design), so you need a trusted method for sourcing your DBIs.
- If DBIs come from the same route then you can loop through them to retrive values, but if you're mixing and matching with DBIs from a different loop you're going to have to use the CHANGE_CONTEXTS function.
- Whilst most developers use the +1 method for looping, making use of the some of the pre-defined loop and array functions (like FIRST, EXISTS and NEXT) is often a better choice.
 
