#!/bin/bash
# author: Md. Asif Haider (1805112) on December 5, 2022

# assignment grader method 
assignment_grader(){
    # checking for exactly 2 arguments
    if [[ $# -eq 2 ]]; then
        # imposing student id restrictions
        if [[ "$2" -ge "1" && "$2" -le "9" ]]; then
            max_score=$1
            max_student_id=$2
        else 
            echo "Student id must be in between 1 to 9 inclusive!"
            exit 1
        fi
    # default student no. set to 5
    elif [[ $# -eq 1 ]]; then
        max_score=$1
        max_student_id=5
    # default max score set to 100
    else 
        max_score=100
        max_student_id=5
    fi
    
    initial_student_id=180512   # common id segment

    echo "student_id,score" >> output.csv   # output csv header

    # checking for exact directory and shell script
    for((i=1;i<=$max_student_id;i++)); do
        # creating new student id each time
        student_id=$initial_student_id"$i"
        if [ -e "./Submissions/$((student_id))/$((student_id)).sh" ]; then
            # execute permission grant
            chmod +x ./Submissions/$((student_id))/$((student_id)).sh
            # copied to temporary file 1
            ./Submissions/$((student_id))/$((student_id)).sh > "SubmittedOutput.txt"

            # regular expression match finding
            mismatch=$(diff --ignore-all-space SubmittedOutput.txt AcceptedOutput.txt | grep '<\|>' | wc -l)
            
            # score penalty
            penalty=$(( $mismatch * 5 ))
            initial_score=$(( $max_score - $penalty ))

            # fixing negative scores
            if [[ "$initial_score" -le "0" ]]; then
                initial_score=0
            fi

            # copy checking start
            for((j=1;j<=$max_student_id;j++)); do
                # ignoring itself
                if [ $i -ne $j ]; then
                    checking_id=$initial_student_id"$j"
                    if [ -e "./Submissions/$((checking_id))/$((checking_id)).sh" ]; then
                        chmod +x ./Submissions/$((checking_id))/$((checking_id)).sh

                        # copied to temporary file 2
                        ./Submissions/$((checking_id))/$((checking_id)).sh > "TemporaryOutput.txt"
                        # exact copy found
                        if [ "$(diff SubmittedOutput.txt TemporaryOutput.txt)" = "" ]; then
                            # negative penalty
                            initial_score=-$((initial_score))
                            break
                        fi
                    fi
                fi
            done
        # assignment not turned in
        else
            initial_score=0
        fi
        
        # final output storing
        echo "$student_id,$initial_score" >> output.csv

    done
    # deleting temporary files 1 and 2
    rm SubmittedOutput.txt TemporaryOutput.txt
}

# program entry point 
# variable argument checking
if [[ $# -ge 3 ]]; then
    echo "At most two arguments allowed!"
    exit 1
# imposing max score restrictions
elif [[ $1 -gt 0 ]]; then
    assignment_grader $1 $2
else 
    echo "Max score must be positive integer!"
    exit 1    
fi