  #Name:Qian Zhiying
  #Email:zqianab@connect.ust.hk
 



  #==================#
  #  THE SNAKE GAME  #                
  #==================#
  
  #--------- DATA SEGMENT --------#
      .data
      
      speed:          .word 5                      # initial speed (in pixels/screen update) (speed must be a multiple of the snake's part size)
      
      snakeHead:      .word -1 200 200 1 5 0       # 6 words for 6 properties of the snake: (in this order) object id, top-left corner's x-coordinate, top-left corner's y-coordinate, image_index, speed_h, speed_v
      snakeHeadSize:  .word 40 40
      snakeBoxSize:   .word 40 40
      
      snakeBoxNo:     .word 6                     # maximum number of snake body boxes                                                                       
      snakeBody:      .word -1:64                 # 4 words for 4 properties of a snake box: object id, image_idx, top-left coner's x-coordinate, and top-left corner's y-coordinate
                                                  # assumption: snake cannot have more than 100 body boxes
      snakeTargetPos: .word -1:32                 # 2 words per snake body box that represent's moving target
                                                                                            
      foodState:      .word -1 -1 0 0             # 4 words that represent a food object: object ID, image_idx, top-left corner's x-coordinate, top-left corner's y-coordinate           
      foodPicSize:    .word 54 54                 # size of a food image                                            
      
      
      
      ##############
      #  BONUS PART
      ##############
      bonusID:        .word 0                      # the id used for the bonus part only (ID of the sliding border)
      bonusIDtmp:     .word 0                      # this value is only used for making the program work (don't need to modify it)
      bonusXCoord:    .word 0                      # this value is only used for the bonus part (current x coordinate of the sliding border) 
      bonusDirection: .word 0                      # this value is only used for the bonus part (direction of the sliding border: 0 - moving right, 
	                                           #                                                                               1 - moving left)
      
      #######################
      # BONUS PART AENDS HERE
      #######################
      
      
      # Game Messages
      msg0:         .asciiz "Enter the number of milliseconds for which a food item appears on the screen [4000, 8000]: "
      msg1:         .asciiz "Time duration is wrong. Try again [4000, 8000]: "
      msg2:         .asciiz "Enter the seed for random number generator: "
      msg3:         .asciiz "You have won!"
      msg4:         .asciiz "You have lost!"
      msg5:         .asciiz "Score: "
      msg6:         .asciiz "Level: "
      newline:      .asciiz "\n"
      testTAB:      .asciiz "\t"
      testMSG:      .asciiz "Testing output"
      testEXIT:     .asciiz "Terminating program"


      title:        .asciiz "The Snake Game"
      # game image array constructed from a string of semicolon-delimited image files
      #array index                0                      1                    2                       3                4                5                6               7                      8             
      images:       .asciiz "horizontal_border.png;snake_head_right.png;snake_head_down.png;snake_head_left.png;snake_head_up.png;snake_box.png;flower_food_one.png;flower_food_two.png;poison_food.png"


      # The following registers are used throughout the program for the specified purposes,
      # so using any of them for another purpose must preserve the value of that register first:
      # $s0 -- initial food item duration (milliseconds)
      # $s1 -- current game score
      # $s2 -- current game level
      # $s3 -- current snake's length (number of boxes) (does not include the head)
      # $s4 -- the time when the food item is placed (for checking if the item has to be placed at a new position)
      # $s5 -- starting time of a game iteration


  #---------- TEXT SEGMENT -------#
    .text
    

main:
#------- Program begins here (same as main in C++) ------------

    jal settingGame               # take some inputs from the player
    
    ori $s1, $zero, 0             # score = 0 
    ori $s2, $zero, 1             # game level = 1
    ori $s3, $zero, 4             # initial snake's length (number of boxes)
    
    
    jal createGame                # create the game screen
    
    
    #---- initialize game objects and borders, finish creating the game screen -----
    jal playSound                 # play background music
    jal createGameObjects         # create game objects
    jal setGameStateOutput    
    
    
    jal initGame                  # initialize the first game level
    
    
    jal updateGameObjects
    jal createGameScreen    
    
main_obj:
    jal getCurrentTime			# Step 1 of the game loop 
    ori $s5, $v0, 0    			# $s5 keeps the iteration starting time

    jal processInput			# Step 2 of the game loop
    
    
    jal collisionDetectionSnake		# Step 3 of the game loop


    jal isLevelOver		        # Step 4 of the game loop
    bgtz $v0, main_next_level		# the player wins the current level
 
	
    jal needMoveFoodItem 		# Step 5 of the game loop
    jal moveSnake	                # Step 6 of the game loop
    
    ############################ BONUS ############################################
    ori $t0, $zero, 2
    bne $s2, $t0, updateScreen
    jal moveSlidingBorder               # Step 7 of the game loop (bonus part)
    ########################### BONUS ENDS HERE ################################## 
    
    
updateScreen:
    jal updateGameObjects		# Step 7 of the game loop
    jal redrawScreen

    ori $a0, $s5, 0			# Step 8 of the game loop
    li  $a1, 30
    jal pauseExecution
    
    j main_obj
	
main_next_level:	
    li   $t0, 2			# the last level is 2
    beq  $s2, $t0, mainGameWin 	# the last level and hence the whole game is won 
    addi $s2, $s2, 1		# increment level
    
    # increment the speed of the snake
    la   $t0, speed
    lw   $t1, 0($t0)
    sll  $t1, $t1, 1
    sw   $t1, 0($t0)
    # double speed and reiniliaze the snake
    jal reinitializeSnake
    # reduce food appearance time by 2
    srl  $s0, $s0, 1
    # reset score
    ori  $s1, $zero, 0
    # set the intial length of the snake
    ori $s3, $zero, 4
    
    #----- re-initialize game objects and information for next level --------
    jal createGameObjects
    jal setGameStateOutput
    jal initGame				# initialize the next game level
    #-------------------------------------------------------------------------
    j updateScreen

mainGameWin: 
    # play the end music
    li $v0, 100	
    li $a0, 18
    li $a1, 4
    syscall
    
    jal setGameWinningOutput		# Game over, and output a game winning message
    jal redrawScreen   
    #j printObjectIDs
    j end_main
mainGameLose: 
    li $v0, 100	
    li $a0, 18
    li $a1, 3
    syscall
    jal setGameLosingOutput			# Game over, and output a game losing message
    jal redrawScreen   
    j end_main


#-------(End main)--------------------------------------------------
end_main:
# Terminate the program
#----------------------------------------------------------------------

    li $v0, 100	
    li $a0, 10
    syscall
    ori $v0, $zero, 10
    syscall


# Function: setting up the duration for food appearance (ms) and random seed from the player
settingGame:
#===========================================================================================
    addi $sp, $sp, -4  # prepare for another jal
    sw $ra, 0($sp)
    
    # Receive an input value and check if it satisfies the requirements [300, 3000]                
    
    la $a0, msg0        # Enter the initial duration
    li $v0, 4
    syscall
    
    li $v0, 5           # cin >> duration
    syscall 
    
    or $a0, $v0, $zero
    
    jal checkLimits    # check the input value
    
    or $s0, $v0, $zero # store the initial duration  
    
    
    la $a0, newline
    li $v0, 4
    syscall
    
    la $a0, msg2       # Enter the seed for random number generator
    li $v0, 4
    syscall
    
    li $v0, 5          # cin >> seed
    syscall
    
    or $a0, $v0, $zero
    jal setRandomSeed  # set the seed
    
    
    lw $ra, 0($sp)     # retrieve the original value of the address register
    addi $sp, $sp, 4
    jr $ra

        
#Function: check if the input value is within the given range
# in: $a0 - received duration    
checkLimits:
#===============================================================
    or $t0, $a0, $zero
      
    li $t1, 8000       # maximum duration (8000ms or 8s) 
    li $t2, 4000       # minimum duration (4000ms or 4s)                 
    
wrong_limits:
    slt $t3, $t1, $t0  # check if exceeds max limit
    slt $t4, $t0, $t2  # check if below min limit
    
    or $t5, $t3, $t4
    beq $t5, $zero, done_check
    
    # the value is not within the limits
    la $a0, msg1
    li $v0, 4
    syscall
    
    li $v0, 5          # cin >> duration
    syscall   
    
    or $t0, $v0, $zero
    j wrong_limits
    
    
done_check:
    or $v0, $t0, $zero
    jr $ra   


#Function: set the seed of the random number generator to $a0
#in: $a0 -- the seed number
setRandomSeed:
#------------------------------------------------------------
    ori $a1, $a0, 0
    li $v0, 40
    li $a0, 1
    syscall
    
    jr $ra


#Function: start playing the background song
playSound:
#-------------------------------------------
    li $v0, 100
    li $a0, 17
    li $a1, 0		# $a1 = sound ID
    syscall
    jr $ra



#Function: create a new game (the first steps in the game creation)
createGame:
#-----------------------------------------------------------------
    li $v0, 100
    
    li $a0, 1           # create the game screen
    li $a1, 800		# game screen width
    li $a2, 800		# game screen height
    la $a3, title	# game's title
    syscall
    
    li $a0, 3		# Set the image array in game
    la $a1, images      # $a1, base address of a string
    syscall		# the images will be stored in an array in the game
    			# the order of the images in the array starting from 0
    
    li $a0, 5
    li $a1, -1          # set background image index
    syscall		# a negative number for filling the background with black
    
    jr $ra


#----------------------------------------------------------------------------------------------------------------------
## Function: pause execution for X milliseconds from the specified time T (some moment ago). If the current time is not less than (T + X), pause for only 1ms.    
# $a0 = specified time T (returned from a previous calll of getCurrentTime)
# $a1 = X amount of time to pause in milliseconds 
pauseExecution:
#===================================================================
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	add $a3, $a0, $a1
	jal getCurrentTime
	
	sub $a0, $a3, $v0
	slt $a3, $zero, $a0
	bne $a3, $zero, positive_pause_time
	li $a0, 1     # pause for at least 1ms

positive_pause_time:
	li $v0, 32	 
	syscall

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#Function: redraw the game screen with the updated game screen objects
redrawScreen:
#===================================================================
    li $v0, 100   
    li $a0, 6
    syscall
    
    jr $ra



#----------------------------------------------------------------------------------------------------------------------
# Function: set the location, font and color of drawing the game-over string object (drawn with a winning notification message once the game is won) in the game screen
setGameWinningOutput:				
#===================================================================
    li $v0, 100		# gameover string
    li $a1, 4           # id of te output window
    
    li $a0, 13		# set object to game-over string
    la $a2, msg3				
    syscall
	
    # location
    li $a0, 12
    li $a2, 200
    li $a3, 350				
    syscall

    # font (size 40, bold, italic)
    li $a0, 16
    li $a2, 80
    li $a3, 1
    li $t0, 1				
    syscall


    # color
    li $a0, 15
    li $a2, 0x00ffff00   # yellow				
    syscall

    jr $ra



#----------------------------------------------------------------------------------------------------------------------
# Function: set the location, font and color of drawing the game-over string object (drawn with a losing notification message once the game is lost) in the game screen
setGameLosingOutput:				
#===================================================================
    li $v0, 100	# gameover string
    li $a1, 4   # id of the output window

    li $a0, 13	# set object to game-over string
    la $a2, msg4				
    syscall
	
    # location
    li $a0, 12
    li $a2, 200
    li $a3, 350				
    syscall

    # font (size 40, bold, italic)
    li $a0, 16
    li $a2, 80
    li $a3, 1
    li $t0, 1				
    syscall


    # color
    li $a0, 15
    li $a2, 0x00ff0000   # red				
    syscall

    jr $ra


#Function: create the game screen objects
createGameObjects:
#----------------------------------------
    li $v0, 100
    li $a0, 2            # code for creating game objects
    			 # any existing ones will be removed first
    			 # $a1 = number of objects (at most 231) to create
    			 # all the objects are nothing, and are assgined 
    			 # 0,1,2,...,a1-1
    addi $a1, $zero, 4   # 4 game state outputs (text and value)
    addi $a1, $a1, 1     # gameover output
    addi $a1, $a1, 2     # need 2 objects to make bonus work
    
    
    # store the ID for future
    addi $t0, $a1, -2    # one border
    addi $t1, $a1, -1    # object to make the bonus work
    la $t2, bonusID
    sw $t0, 0($t2)
    la $t2, bonusIDtmp
    sw $t1, 0($t2)
    
    la   $t0, foodState	   # load the address of foodstate
    addi $t1, $a1, -1
    sw   $t1, 0($t0)       # store food object's id 
			   # foodState:      .word -1 -1 0 0 , first is food id
    addi $a1, $a1, 1       # one food object (ID = 6)
    
    or   $t0, $a1, $zero   # get the number of non-snake objects, $t0
        
    addi $a1, $a1, 1       # one snake head
    
    la   $t1, snakeBoxNo
    lw   $t2, 0($t1)       # load the maximum length of snake's body
    add  $a1, $a1, $t2 	   # 
     
    syscall                # create the objects
    
        
    addi $sp, $sp, -4
    sw   $ra, 0($sp)       # save the return address before calling a new function
    ori  $a0, $t0, 0       # pass function parameters
    			   # here, $t0 is the number of non-snake objects
    			   # include, images, texts, bounds, food
    			   # so $t0 is the ID of head
        
    jal assignSnakeIds     # get the created snake body box ids  
       
       
    lw   $ra, 0($sp)       # restore the address
    addi $sp, $sp, 4
    
            
    jr $ra  
    

#Function: set snake part ids
#in: $a0 - number of non-snake objects
# assumption: snake body parts are always the last objects
assignSnakeIds:
#---------------------------------------------------------
    addi $t0, $a0, -1        # get an ID for the snake's head
    
    la   $t1, snakeHead
    sw   $t0, 0($t1)         # store the ID of the snake's head
    addi $t0, $t0, 1         # update the ID
    
    la   $t1, snakeBoxNo
    lw   $t2, 0($t1)         # get the number of snake body parts (excluding the head)
    
    la   $t1, snakeBody      # the address of the snake body part array
    
    ori  $t3, $zero, 0       # initialize a counter to 0
    
body_loop:
    slt  $t4, $t3, $t2
    beq  $t4, $zero, done_body_loop
    sll  $t4, $t3, 4         # 2*2*2*2 (step size is 4 items and each item 4 bytes)
    add  $t4, $t4, $t1
    sw   $t0, 0($t4)         # store the id of an object
     
    
    addi $t0, $t0, 1         # ++id;
    addi $t3, $t3, 1         # ++counter;  
    j body_loop
       
done_body_loop:

    jr $ra
                    
    

# Function: check if the current level continues or reaches wining state.
# Winning state: snake's length is equal to a fixed maximum	
# return $v0 -- 1 if the level is won, 0 -- the level continues
isLevelOver:
#---------------------------------------------------------------------------------------------------------
    
    li $v0, 0               # assume need to continue
    la $t0, snakeBoxNo
    lw $t1, 0($t0)
    
    # $s3 stores the current length of the snake's body
    bne $t1, $s3, continue_game
    li $v0, 1
    
    
continue_game:
    jr $ra     
  
    
    


#Function: set the location, colour and font of drawing the game state's output objects on the game screen
setGameStateOutput:
#---------------------------------------------------------------------------------------------------------
    li $v0, 100
    
    # score text's location
    li $a1, 0
    li $a0, 12
    li $a2, 80
    li $a3, 60
    syscall
    
    # set score object to represent a text string
    li $a1, 0
    li $a0, 13
    la $a2, msg5
    syscall
    
    #  font (size 20, plain)
    li $a0, 16
    li $a2, 20
    li $a3, 0
    li $t0, 0
    syscall
    
    # colour
    li $a0, 15
    li $a2, 0x00ffffff  # white
    syscall
    
    # score number's location
    li $a1, 1
    li $a0, 12
    li $a2, 160
    li $a3, 60
    syscall

    #  font (size 20, plain)
    li $a0, 16
    li $a2, 20
    li $a3, 0
    li $t0, 0
    syscall
    
    # colour
    li $a0, 15
    li $a2, 0x00ffffff  # white
    syscall    
    
    # initialize the current game score to $s1
    li $a0, 14
    or $a2, $s1, $zero
    syscall
    
    # level text's location
    li $a1, 2
    li $a0, 12
    li $a2, 80
    li $a3, 100
    syscall
    
    # set level object to represent a text string
    li $a1, 2
    li $a0, 13
    la $a2, msg6
    syscall
    
    #  font (size 20, plain)
    li $a0, 16
    li $a2, 20
    li $a3, 0
    li $t0, 0
    syscall
    
    # colour
    li $a0, 15
    li $a2, 0x00ffffff  # white
    syscall
    
    # level number's location
    li $a1, 3
    li $a0, 12
    li $a2, 160
    li $a3, 100
    syscall

    #  font (size 20, plain)
    li $a0, 16
    li $a2, 20
    li $a3, 0
    li $t0, 0
    syscall
    
    # colour
    li $a0, 15
    li $a2, 0x00ffffff  # white
    syscall
    
    # initialize the level to the current level value ($s2)
    li $a0, 14
    or $a2, $s2, $zero
    syscall

    jr $ra


#Function: initialize a new level
#Place the snake at its initial position and set its direction
# to the initial direction
# Place the food item at a radom place so that it would not overlap 
# the snake and the screen border
initGame:
#------------------------------------------------------------------------------
    addi $sp, $sp, -4    # many function calls
    sw   $ra, 0($sp)     # save the return address
    
    # initialize the snake
    jal initSnakeObject
    
    # initialize the food item
    jal placeFoodItem
    
    li $t0, 2
    blt $s2, $t0, no_extra_borders_yet
extra_borders:
    jal addExtraBorder
    ############### BONUS #####################
    #    Addd extra code here for creating the additional border.
    #    The border must only be created when level 2 is reached  
    #    You should implement and use the 'addExtraBorder' procedure.                  
    ############### BONUS ENDS HERE ###########

no_extra_borders_yet:        
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    



#Function: initialize the snake object (head and the current length of body boxes/images)
# Head has the initial direction and it is moving in the initial direction
initSnakeObject:
#----------------------------------------------------------------------------------------
    
    addi $sp, $sp, -8
    sw   $s0, 4($sp)
    sw   $s1, 0($sp)
    

    # save the x-coordinate of the head
    la $t0, snakeHead
    lw $s0, 4($t0) # store the x cordinate of the snake's head
    lw $s1, 8($t0) # store the y cordinate of the snake's head

    
    # since this is the initial stage,
    # no complicated logic is required
    # just append the number of body boxes to the left of the head
    
    la $t0, snakeBoxSize
    lw $t2, 0($t0)           # keep the size of a box image
    la $t0, snakeBody        # load the address of snake body array
 
    # initialize the first body part directly
    la $t1, snakeTargetPos
    addi $t4, $zero, 5       # constant image index
    
    # target of a snake movement
    # the next movement is to go to the previous postion of the head
    sw $s0, 0($t1)
    sw $s1, 4($t1) 
                   
    # the x coordinate is just the head's x - size of the box image
    # then we should store the next x cooridate
    # which is the head - $t2, $t2 is the size of box image
    sub $s0, $s0, $t2  # next x coordinate is stored in $s0    
    
    # then we should update the snake body
    # the previous one need not be stored because it becomes the head
    sw $t4, 4($t0)         # image idx
    sw $s0, 8($t0)         # x coordinate
    sw $s1, 12($t0)        # y coordinate
    
    # increment pointers
    addi $t1, $t1, 8
    addi $t0, $t0, 16
    # $t1: snaketargetpos, only 2 words per snake body box that represent's moving target
    # $t0: snake body,  4 words for 4 properties of a snake box: object id, image_idx, x, y
    
    
    or $t3, $zero, 1         # initialize counter to 1
    
     
init_body_loop:
    beq $t3, $s3, done_init_body_loop    # need to loop through all visible boxes
    
    
    # target of a snake movement
    sw $s0, 0($t1)
    sw $s1, 4($t1) 
    
    
    # the x coordinate is just the head's x - size of the box image
    sub $s0, $s0, $t2  # next x coordinate is stored in $s0    

    
    sw $t4, 4($t0)         # image idx
    sw $s0, 8($t0)         # x coordinate
    sw $s1, 12($t0)        # y coordinate
    
    addi $t0, $t0, 16
    addi $t1, $t1, 8
    addi $t3, $t3, 1  # counter++;   
    j init_body_loop     

done_init_body_loop:
    
    lw   $s0, 4($sp)
    lw   $s1, 0($sp)
    addi $sp, $sp, 8
    
    jr $ra



#Function: place the food item somewhere randomply, but ensure no collision with the snake
#          and the food itme cannot be placed outside the screen. You must ensure
#          that the food item fully appears within the screen ==> any edge of the food image
#          cannot be less than 0 or greater than 799. 
placeFoodItem:
#-----------------------------------------------------------------------------------------
    
    
    #######################
    # For generating random integers, use syscall 41 ($v0 = 41)
    #
    ######################
    ############
    # Generate a random number in within the range [0,2]
    # Add to the generated bumber 6 so that and index of the food image
    # is within the range [6, 8]
    #
    #
    ############
    ##############
    # Generate random numbers and check if they would not place the food image outside
    # the screen
    ##############
    #save the parameters
    addi $sp, $sp, -48
    sw $s7, 44($sp)
    sw $s6, 40($sp)
    sw $s3, 36($sp)
    sw $s4, 32($sp)
    sw $ra, 28($sp)
    sw $s2, 24($sp)
    sw $s1, 20($sp)
    sw $s0, 16($sp)
    
    move $s7, $s3       #save the $s3's value to $s7
    move $s6, $s2
    la $t0, foodPicSize #t0 is the address of foodPicSize
    lw $s3, 0($t0)	#$s3 is the width of the food
    lw $s4, 4($t0)	#$s4 it the height of the food
    
    
    
food_head_body_collison_loop:
			#Here we choose a random position of food
			#However, the scope is set so there is no need to use BounderCheck
    li $t3, 800		#the size of the picture
    sub $t1, $t3, $s3	#t1 is the higher bound is 800-food width
    sub $t2, $t3, $s4	#t2 is the higher bound is 800-food height
    
    li $v0, 42		#call a random
    li $a0, 1		#one random number
    addi $a1, $t1, 0	#set the higher bound
    syscall
    
    addi $t1, $a0, 0   # the random x of food x:(0, 800-food width)
    
    li $v0, 42
    li $a0, 1
    addi $a1, $t2, 0
    syscall
    
    addi $t2, $a0, 0	#the random y of food y:(0, 800-food height)
    
    #Until now, the food will not exceed the border
    #then to check whether the food will collide with the body & head
    move $a2, $t1	#parameters, food leftx is saved in $a2
    move $a3, $t2	#parameters, food topy is saved in $a3
    
    			#$s1 is the width of the food
    			#$s2 is the height of the food
    add $t1, $a2, $s3   #right x of food
    sw $t1, 4($sp)	#save right x to 4($sp)  
    add $t2, $a3, $s4	#bottom y of food
    sw $t2, 0($sp)	#save bottom y to 0($sp)
    
    la $t0, snakeHead   #load the address of snakeHead
    lw $a0, 4($t0) 	#a0, head left x
    lw $a1, 8($t0) 	#a1, head top y
    
    la $t0, snakeHeadSize
    lw $t3, 0($t0)      # size of snake's head
    add  $t0, $a0, $t3  # head right x
    sw $t0, 12($sp)	# save the head right x to 12$sp
    add  $t1, $a1, $t3  # head bootom y
    sw $t1, 8($sp) 	# save the head bottom y to 8$sp
    
    jal checkObjectCollision
    
    beq  $v0, 1,  food_head_body_collison_loop
     
   
    ori  $s0, $zero, 0      # initialize counter to 0 
    la   $s1, snakeBody     # save adress of the body array 
    la   $t0, snakeBoxSize  
    lw   $s2, 0($t0)        # save the size of a body part's image
    
    
    
food_body_part_collision_loop:
    beq $s0, $s7, food_head_body_no_collision
    
    lw  $a0, 8($s1)       # top-left corner's x coordinate
    lw  $a1, 12($s1)      # top-left corner's y coordinate
    add $t1, $a0, $s2     # calculate x coordinate of the right edge
    sw  $t1, 12($sp)       # push onto stack
    add $t0, $a1, $s2     # calculate y coordinate of the bottom edge
    sw  $t0, 8($sp)       # push onto stack
    
    jal checkObjectCollision
    
    addi $s0, $s0, 1      # counter++;
    addi $s1, $s1, 16     # increment pointer
    beq  $v0, 1, food_head_body_collison_loop
    j food_body_part_collision_loop
    
food_head_body_no_collision:
    
    li $t1, 2
    bne $s6, $t1,   food_no_collision
    move $a0, $a3
    jal checkIfNewFoodItemOverlapExtraBorder
    beq $v0, 0, food_head_body_collison_loop
    #then we need to check whether there is collision with the border

food_no_collision:   
    #it ok to add the position
    #a2, a3 is the target coordinate
    la $t0, foodState
    sw $a2, 8($t0)
    sw $a3, 12($t0)
    
    li $v0, 41		#generate a random number
    syscall
    remu $a0, $a0, 3	#ramainder: 0, 1, 2
    addi $a0, $a0, 6	#a0: 6, 7, 8
    
    sw $a0, 4($t0)
     
     
    lw $s3, 36($sp)
    lw $s4, 32($sp)
    lw $ra, 28($sp)
    lw $s2, 24($sp)
    lw $s1, 20($sp)
    lw $s0, 16($sp)
    lw $s7, 44($sp)
    lw $s6, 40($sp)
    addi $sp, $sp, 48
    
    ##########
    # C++ Pseudo code for generating a random number within a range [7, 15]:
    #
    # #include <cstdlib>
    # #include <ctime>
    # using namesapce std;
    #
    # int getRandNumWithinRange() {
    #
    #   srand(time(NULL)); // random seed to init random number generator. You may use either passed integer at the beginning of the program or current time. Does not matter.
    #   int rand_int = rand() % 9;      // get a random integer in the range [0, 8]
    #   int final_int = rand_int + 7;   // an integer in the range [7, 15]  
    #   return randInt;
    # }
    ##########
    ###############
    # Make sure that the food item won't overlap with any part of the snake
    # if it is placed at the radomly generated position
    ###############
   
     
    ############################# BONUS PART ###########################################
    # Before moving further check if the extra border has been introduced  and if it does not overlap with
    # the food item. If it does, redo everything.
    # You should implement and use the 'checkIfNewFoodItemOverlapExtraBorder' procedure
    
    ################## BONUS PART ENDS HERE ###########################################
    
    
    jr $ra


#Function: get the point value of a food image
# Some images give a positive value (+10), some a negative value (-10)
# in: $a0 -- image index
# return: $v0 -- the value of this food image 
getFoodPoints:
    addi $t0, $zero, 8
    slt  $t1, $a0, $t0, 
    beq  $t1, $zero, negative_image_value
    
    addi $v0, $zero, 10 # positive value
    
    jr $ra

negative_image_value:
    addi $v0, $zero, -10 # negative value
    
    jr $ra





#---------------------------------------------------------------------------------------------------------------------
# Function: collision detection between snake's head and any of three:
# 1. border --> lost game
# 2. its own body part --> lost game
# 3. food item  --> update the score and snake's body according to the value of the food 
#    If the snake hits a poisonous food item, reduce the point value and reduce
#    the length of the snake. If the length < initial length --> lost game
collisionDetectionSnake:
#---------------------------------------------------------------------------------------------------------------------

     
    # collision with border
    addi $sp, $sp, -40
    sw   $s6, 36($sp)
    sw   $s7, 32($sp)
    sw   $ra, 28($sp)
    sw   $s2, 24($sp)
    sw   $s1, 20($sp)
    sw   $s0, 16($sp)	
#################### BONUS CODE ######################
#  Add extra code here for checking if any part of the snake
# does not overlap with the extra border.
# You should implement and use the 'checkExtraBorderCollision' procedure
################### BONUS ENDS HERE #################    
    # judge which level is 
    li $t0, 2
    beq $s2, $t0, bonus_border_head_check
    j no_bonus_border_check
    
bonus_border_head_check:

    la $t0, snakeHead
    la $t1, snakeHeadSize
    lw $a0, 4($t0) # the x of snake head
    lw $a1, 8($t0) # the y of snake head
    lw $t2, 0($t1) # the width of snakeHead
    lw $t3, 4($t1) # the height of snakeHead
    add $a2, $t2, $a0
    add $a3, $t3, $a1
    jal checkExtraBorderCollision
    beq $v0, 0, bonus_border_body_check
    j game_lost_state
    
bonus_border_body_check:
    
    li $s0, 0   # the counter
   
    la $s1, snakeBody
    la $s2, snakeBoxSize
    
    lw $s6, 0($s2) # the width of the snake Body
    lw $s7, 4($s2) # the height of the sanke Body
    
    
bonus_border_body_check_loop:
   
    beq  $s0, $s3, bonus_border_body_check_loop_end
    lw $a0, 8($s1) #a0: the x of body
    lw $a1, 12($s1) #a1: the y of body
    add $a2, $a0, $s6 #a2: right x of body
    add $a3, $a1, $s7 #a3: bottom y of body
    jal checkExtraBorderCollision
     
    bne $v0, 0, bonus_border_body_check_lose
    addi $s1, $s1, 16
    addi $s0, $s0, 1
    j bonus_border_body_check_loop
    
bonus_border_body_check_lose:
    j game_lost_state
    
bonus_border_body_check_loop_end:

	
no_bonus_border_check:	
    # if the head hits the border (screen edge)
    # the game is over
    la $t0, snakeHead
    lw $a0, 4($t0)      # top-left corner's x value
    lw $a1, 8($t0)      # top-left corner's y value
    la $t0, snakeHeadSize
    lw $t3, 0($t0)      # size of snake's head
    add  $a2, $a0, $t3
    addi $a2, $a2, -1
    add  $a3, $a1, $t3
    addi $a3, $a3, -1
    
	
    jal hitBorderCheck  # check if a border is hit
    
         
    beq $v0, $zero, check_body_hit
    j game_lost_state    # lost game
    
                
                                    
check_body_hit:
    # need to check if the snake's head does not hit its body
    # $s3 hodls the number of body parts
    # since the previous function calls
    # did not modify the $a registers,
    # don't need to change many values
     
     
    # new head's coordinates 
    la  $t0, snakeHead
    lw  $a0, 4($t0)
    lw  $a1, 8($t0) 
    
    la  $t0, snakeHeadSize
    lw  $t1, 0($t0)
    
    # compute other edges of the image
    add $t0, $a0, $t1
    add $t3, $a1, $t1
    
    # push some values onto the stack  
    sw $t0, 12($sp)
    sw $t3, 8($sp)
    
    # need to loop through all body parts
    # and check for collision
    ori  $s0, $zero, 1      # initialize counter to 1 since the head cannot hit the body part that is directly attached to it
    la   $s1, snakeBody     # save adress of the body array
    addi $s1, $s1, 16       # skip the directly attached body part 
    la   $t0, snakeBoxSize  
    lw   $s2, 0($t0)        # save the size of a body part's image
    
    
body_part_collision_loop:
    beq $s0, $s3, check_head_food_hit
    
    lw  $a2, 8($s1)       # top-left corner's x coordinate
    lw  $a3, 12($s1)      # top-left corner's y coordinate
    add $t1, $a2, $s2     # calculate x coordinate of the right edge
    sw  $t1, 4($sp)       # push onto stack
    add $t0, $a3, $s2     # calculate y coordinate of the bottom edge
    sw  $t0, 0($sp)       # push onto stack
    
    jal checkObjectCollision
    
    addi $s0, $s0, 1      # counter++;
    addi $s1, $s1, 16     # increment pointer
    beq  $v0, $zero, body_part_collision_loop
    
    
    # collision -> lost game
    j game_lost_state
    



check_head_food_hit:
    
    # snake does not doe ==> the head does not hit any other body part or any
    # border. However, one extra case left. You need to check if the snake's
    # head hits the food item. If it does, you need to take actions.
    
    # Step 1: Retrieve the points of the food item (use the 'getFoodPoints' procedure)
    # Step 2: Shorten or make the snake longer according to the points
    # Step 3: If the snake is still alive (read the description of the 'ShortenSnakesBody' procedure), need to place
    #         a new food item.  
    la $t0, foodState
    # t0 is the address of the foodstate
    lw $a0, 8($t0)	# food x
    lw $a1, 12($t0)	# food y
    # t0 is the address of the foodPicSize
    la $t0, foodPicSize
    # then we load the width and length of the food
    lw $t1, 0($t0)
    lw $t2, 4($t0)
    # then we add the width and length to the origin (x,y)
    add $t1, $a0, $t1
    add $t2, $a1, $t2
    # save them to the stack
    sw $t1, 12($sp)
    sw $t2, 8($sp)
    # then we load the snake's head
    la $t0, snakeHead
    # then load the head's (x,y) to a2 and a3
    lw $a2, 4($t0)
    lw $a3, 8($t0)
    # laod the width and length of snake head
    la $t0, snakeHeadSize
    lw $t1, 0($t0)
    lw $t2, 4($t0)
    # 
    add $t1, $a2, $t1
    add $t2, $a3, $t2
    # save them to the stack
    sw $t1, 4($sp)
    sw $t2, 0($sp)
    # then all the parameters are ready
    jal checkObjectCollision
    # if no collison, then end_collision
    beq $v0, $zero, end_collision_detection_snake
    
    # else, we need to deal with the food image and the snake
    la $t0, foodState
    #a0 is the image index of the food
    lw $a0, 4($t0)
    # parameter: $a0 -- image index
    # returns: $v0 -- the value of this food image
    jal getFoodPoints
    
    #Tricky: load the s1 here
    lw $s1, 20($sp)
    # should judge the value
    move $a0, $v0
    blt $a0, $zero, shorten_the_snake
    j enlarge_the_snake

shorten_the_snake:  
    jal shortenSnakesBody
    j end_change_snake

enlarge_the_snake:  
    jal stretchSnakesBody
    j end_change_snake
    
end_change_snake:
    sw $s1, 20($sp)
    #here, we need to change the current time to right now
    #which is, move $v0 to $s4 to avoid dupliate foodreplace
    jal getCurrentTime
    move $s4, $v0
    jal placeFoodItem
    
end_collision_detection_snake:
    # need to restore original values
    # of $s registers
    lw   $s2, 24($sp)
    lw   $s1, 20($sp)
    lw   $s0, 16($sp)
    lw   $ra, 28($sp)
    lw   $s6, 36($sp)
    lw   $s7, 32($sp)
    addi $sp, $sp, 40
    
    jr $ra


game_lost_state:
    # lost state
   
    
    
    jal mainGameLose
    lw   $s2, 24($sp)
    lw   $s1, 20($sp)
    lw   $s0, 16($sp)
    lw   $s6, 36($sp)
    lw   $s7, 32($sp)

    lw   $ra, 28($sp)
    addi $sp, $sp, 40
    
    jr   $ra


#Function: make the snake shorter and decrease the score by the passed value.
# ################## CONDITION #######################
# If the body becomes shorter than the initial length of the snake (4), then
# call the 'mainGameLose' procedure. The current length is stored $s3.

# in: $a0 -- value by which the score will be decreased
shortenSnakesBody:
#---------------------------------------------------------------------------


    # if the length of the snake's body (number of body boxes) becomes
    # less than 4, call the 'mainGameLose' procedure
    # jal mainGameLose
    
    # in this function, s1 - 1 first, then s1 - a0, then update the image index
    # don't forget the syscall and don't forget to end the game

    # Body can be shortened by calling the provided syscall ($v0 == 100)   
    # Here we can modify the value of $s3
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # decrease the score
    add $s1, $s1, $a0
    
    # update the length of the snakeBody
    addi $s3, $s3, -1
    # check whether $s3 < 4, if true, then mainGameLose
    li $t1, 4
    blt $s3, $t1, end_the_game
    # then we need to find the last body
    # load the address of snakeBody
    la $t0, snakeBody
    # t1 = 16 * s3
    sll $t1, $s3, 4
    # t1 = t1 + t0 , get the final address of the snakeBody
    add $t1, $t1, $t0
    # set game object to represent Image
    li $v0, 100
    li $a0, 11
    # get the object ID
    lw $a1, 0($t1)
    # set the -1 to the image index of the body box
    li $t0, -1
    sw $t0, 4($t1)
    # load the -1 and then make the tail disappear
    lw $a2, 4($t1)
    syscall
    
    
    # load the $ra and return the function  
    lw $ra, 0($sp)
    addi $sp, $sp, 4

    jr $ra
end_the_game:
    jal mainGameLose


#Function: stretch snake (append one body part) and increase the score by the passed value.
#          In addition to increasing the game score ($s1), you must also append to the end 
#          of the snake'sody a new body box. This can be done by using the provided syscall ($v0 == 100).

# in: $a0 -- value by which the score will be increased
stretchSnakesBody:
#-----------------------------------------------------------------------------------------
    
    # Place the new tail at the position of the current tail (last body box).
    # This case will not result in a collision.
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # the score is increased by $a0
    add $s1, $s1, $a0
    
    # get the address of the snakeBody
    la $t0, snakeBody
    # get the address of the final body $t1
    addi $t1, $s3, -1
    sll $t1, $t1, 4
    add $t1, $t0, $t1
    # get the coordinate of the final body x,y
    lw $t0, 0($t1)	#t0 is the object ID of the last box
    addi $t0, $t0, 1	#update the object ID
    lw $t2, 4($t1)	#t2 is the image index of the last box
    			#which should be same of all the bodies
    lw $t3, 8($t1)	#t3 is the x-coordinate of the last box
    lw $t4, 12($t1)	#t4 is the y-coordinate of the last box
    # then we reach a next body --- the new body
    addi $t1, $t1, 16
    # save the parameters to the new body
    sw $t0, 0($t1)
    sw $t2, 4($t1)
    sw $t3, 8($t1)
    sw $t4, 12($t1)
    # set game object to represent image
    li $v0, 100
    li $a0, 12
    move $a1, $t0
    move $a2, $t3
    move $a3, $t4
    syscall
    # display the image
    li $v0, 100
    li $a0, 11
    # $t0, the obejct ID of the new last box
    move $a1, $t0
    # $t2, the image index of the new last box
    move $a2, $t2
    syscall
    
    #  then the snake's length should plus 1
    addi $s3, $s3, 1
    
    # then update the snakeTargetPos
    # first we put the head's position to the target postion
    la $t0, snakeHead	#get the address of snakeHead
    lw $t1, 4($t0)	#get the x-coordinate of head
    lw $t2, 8($t0)	#get the y-coordinate of head
    
    # then we load the address of snakeTargetPos
    la $t0, snakeTargetPos
    sw $t1, 0($t0)	#save the body0's next position x
    sw $t2, 4($t0)	#save the body0's next position y
    
  
    # then for each body behind, from 0 ~ $s3-2
    # we put the relative position to snakeTargetPos 1~$s3-1
    # $t0, is the address of sTP
    # $t1, is the address of snakeBody
    # $t2, the count
    addi $t0, $t0, 8   #-> position 1 in sTP
    la $t1, snakeBody  #-> posiion 0 in snakeBody
    li $t2, 0
    addi $t5, $s3, -1  #t5 = s3 - 1, so the count should be less than this number
    
 put_body_pos_loop:
    #	
    beq $t2, $t5, end_put_body_pos_loop
    lw $t3, 8($t1)	# the x of the current box
    lw $t4, 12($t1)	# the y of the current box
    sw $t3, 0($t0)	# put it into the corresponding sTP
    sw $t4, 4($t0)
    
    addi $t0, $t0, 8
    addi $t1, $t1, 16
    addi $t2, $t2, 1
    j put_body_pos_loop
 
 end_put_body_pos_loop:
    
    # After placing the snake's body at the current tail's position 
    # call syscall to make it visible and update the 'snakeTargetPos'
    # structure.
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra 
    

#Function: check if the snake's head hits any border
#in: $a0 -- left edge's x-coordinate of the snake's head,
#    $a1 -- top edge's y-coordinate of the snake's head,
#    $a2 -- right edge's x-coordiante of the snake's head
#    $a3 -- bottom edge's y-coordinate of the snake's head
# return: $v0 = 1 if the head hits a border; otherwise $v0 = 0
hitBorderCheck:
#--------------------------------------------------------------
    
    # need to check four cases:
    # Case 1: if the left edge's x-cooridnate is 0 or less --> hit
    # Case 2: if the right edge's x-coordinate is 799 or more --> hit
    # Case 3: if the top edge's y-coordinate is 0 or less --> hit
    # Case $: if the bottom's edge y-coordinate is 799 or more --> hit
    
    li $v0, 0      # assume no collision
    
    ori $t0, $zero, 799  # screen size is 800 pixels and the range is [0, 799]
    
    # case 1
    slt $t1, $zero, $a0
    bne $t1, $zero, case_2_border_check
    li $v0, 1       # collision
    j end_border_hit_check
 
       
case_2_border_check:
    # case 2
    slt $t1, $a2, $t0
    bne $t1, $zero, case_3_border_check
    li $v0, 1
    j end_border_hit_check
    
    
case_3_border_check: 
    # case 3
    slt $t1, $zero, $a1
    bne $t1, $zero, case_4_border_check
    li $v0, 1
    j end_border_hit_check
    
    
case_4_border_check:
    # case 4
    slt $t1, $a3, $t0
    bne $t1, $zero, end_border_hit_check
    li $v0, 1
            
      
end_border_hit_check:
    jr $ra

#Function: check if two objects collide
#in: $a0     --  left  edge's x-coordinate of image 1, $a1 -- top edge's y coordinate of image 1
#in: $a2     --  left  edge's x-corrdinate of image 2, $a3 -- top edge's y coordinate of image 2
#in: 12($sp) --  right edge's x-coordinate of image 1, 8($sp) -- bottom edge's y coordinate of image 1
#in: 4($sp)  --  right edge's x-coordinate of image 2, 0($sp) -- bottom edge's y coordinate of image 2  
#assumption: all images are rectangles
#return: $v0 = 1 if yes; otherwise $v0 = 0;
checkObjectCollision:
#----------------------------------------------------------------------
     
    # get all four coordinate of image 1
    or $t0, $a0,    $zero # left x-coordinate
    or $t1, $a1,    $zero # top y coordinate of image 1
    lw $t2, 12($sp)       # right x-coordinate of image 1
    lw $t3, 8($sp)        # bottom y-coordinate of image 1
    
    
    # get all four coordinate of image 2
    lw $t6, 4($sp)       # right x-coordinate of image 2
    lw $t7, 0($sp)       # bottom y-coordinate of image 2
    or $t4, $a2, $zero   # left x-coordinate of image 2
    or $t5, $a3, $zero   # top y-coorindate of image 2
   
    
    # Use a simple logic to check if the images overlap
    
    # Cond1. If A's left edge is to the right of the B's right edge, - then A is Totally to right Of B
    # Cond2. If A's right edge is to the left of the B's left edge, - then A is Totally to left Of B
    # Cond3. If A's top edge is below B's bottom edge, - then A is Totally below B
    # Cond4. If A's bottom edge is above B's top edge, - then A is Totally above B
    # for more information refer to: https://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other
    
    # Cond 1:
    slt $v0, $t6, $t0
    beq $v0, $zero, two_object_cond_2
    
    j no_two_object_collision
    
two_object_cond_2:
    # Cond 2:
    slt $v0, $t2, $t4
    beq $v0, $zero, two_object_cond_3
    
    j no_two_object_collision
    
two_object_cond_3:
    # Cond 3:
    slt $v0, $t7, $t1
    beq $v0, $zero, two_object_cond_4
    
    j no_two_object_collision
    
two_object_cond_4:
    # Cond 4:
    slt $v0, $t3, $t5,
    beq $v0, $zero, final_no_collision_case

no_two_object_collision:
    li $v0, 0
    jr $ra                            


# if two objects share a common line, ignore this case
final_no_collision_case:
    beq $t0, $t6, no_two_object_collision
    beq $t1, $t7, no_two_object_collision
    beq $t2, $t4, no_two_object_collision
    beq $t3, $t5, no_two_object_collision
    
    # collision has occurred
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                
two_object_collision:
    li $v0, 1  # collision
    jr $ra
         
    
#---------------------------------------------------------------------------------------------------------------------
# Function: update the game screen objects according to the game data structures in MIPS code here

updateGameObjects:				
#---------------------------------------------------------------------------------------------------------------------
    li $v0, 100
    
    # update game state numbers	
    li $a0, 14
    # set game object represent Integer
    # a1 = object ID
    # a2 = the integer
    # the score number's ID = 1
    
    li  $a1, 1	         # score number
    ori $a2, $s1, 0	
    syscall
	
    # the level number's ID = 3	
    li  $a1, 3	        # level number
    ori $a2, $s2, 0	
    syscall
    
    # get the food's ID, which stored in foodState
    la $t0, foodState
    lw $a1, 0($t0)      # object ID
    
    # $a0=12 -> set game object's location
    # $a1 = object ID
    # $a2 = x-coordinate
    # $a3 = y-coordinate
    li $a0, 12
    lw $a2, 8($t0)      # place the food object on the screen
    lw $a3, 12($t0) 
    syscall
    
    # update the food image
    # $a0 = 11 -> set game object to represent Image
    # $a1 = object ID
    # $a2 = index No to an image in the game's image array
    # if $a2 = negative, then this objects to represent nothing
    
    li $a0, 11          # set this object to represent an image
    lw $a2, 4($t0)      # food's image index
    syscall   
    
    
    
    # snake's head
    # set location
    li $a0, 12
    la $t0, snakeHead
    lw $a1, 0($t0)      # object ID
    lw $a2, 4($t0)      # load the head coordinates
    lw $a3, 8($t0) 
    syscall

   
    # update snake head 
    li $a0, 11          # set this object to represent an image
    lw $a2, 12($t0)     # snake head's image index
    syscall   
      
    
    # update the body of the snake
    la $t0, snakeBody
    
    ori $t1, $zero, 0  # initialize counter to zero
    
update_snake_body_imgs:
    slt $t2, $t1, $s3  # length of the snake
    beq $t2, $zero, done_game_object_updates
    
    # update an item of the body
    sll $t2, $t1, 4
    add $t2, $t2, $t0
    # get the address of the snake body, i*4+$t0
     
    # load coordinates
    li $a0, 12
    lw $a1, 0($t2)      # object ID
    lw $a2, 8($t2)
    lw $a3, 12($t2) 
    syscall  
     
    # set the image
    li $a0, 11
    lw $a2, 4($t2)      # object image
    syscall
   
    
    addi $t1, $t1, 1    # counter++;
    j update_snake_body_imgs
    

done_game_object_updates:

    ##################################################
    #              BONUS PART                        #
    ##################################################
    # move the border on the screen
    ori $t0, $zero, 2
    bne $t0, $s2, done_all_game_object_updates
    
    # need to move the sliding border too
    li $a0, 12
    la $t0, bonusID
    lw $a1, 0($t0)   # load object ID
    la $t0, bonusXCoord
    lw $a2, 0($t0)   # x coord of the sliding border
    li $a3, 400      # y is a constant
    syscall
    
    ##################### BONUS ENDS HERE ##########################
done_all_game_object_updates:    
    jr $ra


#Function: move the snake's head and its body according to the player's input
moveSnake:
#------------------------------------------------------------------------------------
    
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    jal checkIfNewMove
    
    bne $v0, $zero, new_move_movement
    # carry on with the previous snake's movement
    jal snakeOldMovement
    j   done_snake_movement
            
new_move_movement:
    jal snakeNewMovement
    

done_snake_movement:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
    
#Function: handle the snake in the state when it's direction cannot be changed -- continue previous steps    
snakeOldMovement:    
#--------------------------------------------------------------------------------------------------------    

    # Snake cannot change its position whenever its gets the user's input. 
    # In order to make a smooht movement of the snake, snake must 
    # achieve its target. In other words, each part of the snake's body
    # (body box) moves towards its target. Body parts move
    # in an overlapping way, meaning that a body part is moving to 
    # its's preceding body part's old position.
    addi $sp, $sp, -8
    sw $s1, 4($sp)
    sw $ra, 0($sp)
    
    # The snake has not reached its target
    # So it needs to move slowly to its target
    # So I need to update the head & the body. This makes sense!
    # And I think this is to move one distance (speed * 1)
    # Suppose the head can only go forward?
    
    # get the address of the head
    la $t0, snakeHead
    # get the image of the head the judge the direction of the head
    lw $t1, 12($t0)
    # if the head facing right or left, then this is the case of horizental move
    li $t2, 1
    beq $t1, $t2, horizental_move
    li $t2, 3
    beq $t1, $t2, horizental_move
    # if the head facing top or down, then this is the case of vertical move
    li $t2, 2
    beq $t1, $t2, vertical_move
    li $t2, 4
    beq $t1, $t2, vertical_move
    # we should keep $t0 as the address of the snakeHead
horizental_move:
    # get the horizental speed 
    lw $t1, 16($t0)
    # get the x of head
    lw $t2, 4($t0)
    # get the new x of head and save it
    add $t2, $t2, $t1
    sw $t2, 4($t0)
    j body_move
vertical_move:
    # get the vertical speed
    lw $t1, 20($t0)
    # get the y of head, update y by speed and save it
    lw $t2, 8($t0)
    add $t2, $t2, $t1
    sw $t2, 8($t0)
    j body_move
body_move:
    # load the address of body and targetpos
    la $t0, snakeBody
    la $t1, snakeTargetPos
    # t2 is the count, s3 is the current length
    li $t2, 0
body_move_loop:
    beq $t2, $s3, body_move_end
    # (t3,t4) the bodyx's (x,y)
    lw $t3, 8($t0)
    lw $t4, 12($t0)
    # the corresponding target's (x,y)
    lw $t5, 0($t1)
    lw $t6, 4($t1)
    # Here we save the speed first
    la $t7, speed
    lw $s1, 0($t7)
    # then we should judge :
    # if t3 = t5, then must move on the y direction
    beq $t3, $t5, check_y
    # else: which is smaller?
    blt $t3, $t5, move_x_right
    j move_x_left
    
    # t3, t4, t5, t6, should not change -> the ordinate
    # t0, t1 should not change -> address
    # t2 should not change -> count
check_y:
    blt $t4, $t6, move_y_up
    j move_y_down
    
move_x_right:
    add $t3, $t3, $s1
    sw $t3, 8($t0)
    j move_done
move_x_left:
    sub $t3, $t3, $s1
    sw $t3, 8($t0)
    j move_done
move_y_up:
    add $t4, $t4, $s1
    sw $t4, 12($t0)
    j move_done
move_y_down:
    sub $t4, $t4, $s1
    sw $t4, 12($t0)
    j move_done
move_done:
    addi $t0, $t0, 16
    addi $t1, $t1, 8
    addi $t2, $t2, 1
    j body_move_loop
body_move_end:
    
    # HINT: the targets of body parts should be stored in the 'snakeTargetPos' 
    #       data structure.
    lw $ra, 0($sp)
    lw $s1, 4($sp)
    addi $sp, $sp, 8
    jr $ra


#Function: consider the current state of the snake and player's input to determine snake's movement 
snakeNewMovement:    
#-------------------------------------------------------------------------------------------------
    
    # Procedure should refresh the 'snakeTargetPos' with the current 
    # positions of the preceding snake's parts.
    # For example, the snakeTargetPos[0] should be updated to the
    # current position of the head.
    # After updating the 'snakeTargetPos' structure, perform 
    # snake's movement.
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # load the address of t0
    la $t0, snakeBody
    la $t1, snakeTargetPos
    la $t2, snakeHead
    # (t3,t4) is the coordinate of head 
    lw $t3, 4($t2)
    lw $t4, 8($t2)
    # save it to the snakeTarpos
    sw $t3, 0($t1)
    sw $t4, 4($t1)
    
    addi $t1, $t1, 8
    # then we should save the other 0~s3-2 to the snakeTargetPos
    # we should keep the $t0, $t1
    # $t2 is the count, $t3 is the upper bound
    li $t2, 0
    addi $t3, $s3, -1
update_move_loop:
    beq $t2, $t3,update_move_loop_end
    
    lw $t4, 8($t0)
    lw $t5, 12($t0)
    
    sw $t4, 0($t1)
    sw $t5, 4($t1)
    
    addi $t0, $t0, 16
    addi $t1, $t1, 8
    addi $t2, $t2, 1
    j update_move_loop

update_move_loop_end:
    
    #Until now, we have a new snakeTargetPos
    #and the snakeBody has no change
    #also the snake head has no change
    #so we just need to call the snakeOldMovement function
    jal snakeOldMovement
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    

#Function: check if the food image time has expired.
#          If yes, move the food item to a new place.
#          Otherwise, do nothing. 
#          Remember, the food item placement time is
#          stored in $s4.
needMoveFoodItem:
#--------------------------------------------------
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    # get current system time
    jal getCurrentTime
    
    sub $t0, $v0, $s4 
    slt $t1, $t0, $s0
    bne $t1, $zero, no_need_to_move
    
    # need to place the food item  a new place
    jal placeFoodItem
    
    # update the placement time
    jal getCurrentTime
    or $s4, $v0, $zero
    
no_need_to_move:    
    lw   $ra, 0($sp)  
    addi $sp, $sp, 4
    
    jr $ra

 
 
#Function: reinitialize the head of the snake (all values are reset to the ones at top of the code)
reinitializeSnake:
#-------------------------------------------------------------------------------------------------
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # reset structures of the snake's head
    la $t0, snakeHead
    
    # Step 1: reset the position to (200, 200);
    # Step 2: reset the image index to "snake_head_right.png";
    # Step 3: reset the speed values to the initial values. 
    li $t1, 200
    # reset the position to (200,200)
    sw $t1, 4($t0)
    sw $t1, 8($t0)
    # reset the image index to "snake_head_right.png"
    li $t1, 1
    sw $t1, 12($t0)
    # reset the speed values to the initial values
    la $t1, speed
    lw $t2, 0($t1)
    sw $t2, 16($t0)
    
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    
  

#Function: check if the current player's input can be considered
# return: $v0 = 1 if can process the input; $v0 = 0 - cannot.       
checkIfNewMove:
#---------------------------------------------------------------
    
    
    li $v0, 1
    ori $t0, $zero, 0 # counter
    la $t1, snakeTargetPos
    la $t2, snakeBody
    
check_reached_target_loop:
    beq $t0, $s3, can_have_new_move
    
    # check if before moving the snake
    # it has already reached its target
    lw $t3,  8($t2)
    lw $t5,  0($t1)
    lw $t4, 12($t2)
    lw $t6,  4($t1)
    
    bne $t3, $t5, not_reached_target_yet        
    bne $t4, $t6, not_reached_target_yet
    
    # check the next body part
    addi $t0, $t0, 1 # counter++;
    addi $t1, $t1, 8
    addi $t2, $t2, 16
    
    j check_reached_target_loop
    # check if each of the parts has reached the target
    

not_reached_target_yet:
    li $v0, 0        

    
can_have_new_move:
    jr $ra
        
#Function: read and handle the player's input
#This function only changes the image index of snake head
# and the horizental speed & vertical speed of the snake
processInput:
#--------------------------------------------
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    jal checkIfNewMove
    
    # skip this input
    beq $v0, $zero, process_input_end
    
    jal getInput
	
	
    li  $t0, 113		# key q
    beq $v0, $t0, end_main
		
    la $t1 speed
    lw $t2 0($t1)		# $t2 holds speed
	
    la $t1, snakeHead           # $t1 holds the address is the snake's head
	
    li $t0, 97			# key a
    beq $v0, $t0, press_a
	
    li $t0, 100			# key d
    beq $v0, $t0, press_d
	
    li $t0, 119			# key w
    beq $v0, $t0, press_w
	
    li $t0, 115			# key s
    beq $v0, $t0, press_s
	
    j process_input_end


press_d:
    
    # if the snake is already moving to the left
    # no update
    lw $t3, 12($t1)
    li $t4, 3
    beq $t3, $t4, process_input_end  
    
    # set vertical speed to 0 and horizontal speed to positive $t2
    sw $zero, 20($t1)
    sw $t2,   16($t1)
    #set head heading towards right
    li $t3, 1
    sw $t3, 12($t1)
    
    j process_input_end
	
press_a:
     # if the snake is already moving to the right
    # no update
    lw $t3, 12($t1)
    li $t4, 1
    beq $t3, $t4, process_input_end  

    # set vertical speed to 0 and horizontal speed to negative $t2
    sub $t2, $zero, $t2
    sw  $zero, 20($t1)
    sw  $t2,   16($t1)
    # set head heading towards left
    li $t3, 3
    sw $t3, 12($t1)
    
    j process_input_end
	
press_w:
    # if the snake is already moving down
    # no update
    lw $t3, 12($t1)
    li $t4, 2
    beq $t3, $t4, process_input_end  

    # set vertical speed to negative $t2 and horizontal speed to 0
    sub $t2,   $zero, $t2
    sw  $t2,   20($t1)
    sw  $zero, 16($t1)
    # set head heading upwards
    li $t3, 4
    sw $t3, 12($t1)
    j process_input_end
	
press_s:
    # if the snake is already moving up
    # no update
    lw $t3, 12($t1)
    li $t4, 4
    beq $t3, $t4, process_input_end  

    # set vertical speed to positive $t2 and horizontal speed to 0
    sw  $t2,   20($t1)
    sw  $zero, 16($t1)
    # set head heading downwards
    li $t3, 2
    sw $t3, 12($t1)
    j process_input_end

process_input_end:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


# Function: get input character from keyboard, which is stored using Memory-Mapped Input Output (MMIO)
# return: $v0 -- ASCII value of input character if input is available; otherwise the value zero
getInput:
#-----------------------------------------------------------------------------------------------------
	addi $v0, $zero, 0

	lui $a0, 0xffff
	lw $a1, 0($a0)
	andi $a1,$a1,1
	beq $a1, $zero, noInput
	lw $v0, 4($a0)

noInput:	
	jr $ra


#Function: creata and show game screen
createGameScreen:
#--------------------------------------
    li $v0, 100
    li $a0, 4
    syscall 
    
    jr $ra

#Function: get the current time (in milliseconds from a fixed point of some years ago, which may be different in different program execution).
# return: $v0 -- current time in milliseconds
getCurrentTime:
#--------------------------------------------------------------------------------------------------------------------------------------------
    li $v0, 30
    syscall                    # this syscall also changes the value of $a1
    andi $v0, $a0, 0x3fffffff  # truncated milliseconds from some years ago
    
    jr $ra
    
    
    
    
############################################################################################
#    BONUS PART
############################################################################################    

#Function: display one extra border on the screen whose id is bonusID
addExtraBorder:
  
  
  # size of a border mage is 400x50 (length X width)
  # need to place them at coordinate (0, 400) 
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  
  la $t0, bonusID
  lw $t1, 0($t0) #t1 is the border's ID
  la $t2, bonusXCoord
  lw $t3, 0($t2) #t2 is the X coor of border
  
  li $v0, 100
  li $a0, 12
  move $a1, $t1
  move $a2, $t3
  li $a3, 400
  syscall
  
  li $v0, 100
  li $a0, 11
  move $a1, $t1
  li $a2, 0
  syscall
  
  
  
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  
  jr $ra


  
  
#Function: check if a passed object collides with this extra border
#in: $a0 - left edge's x coordinate of the object of interest,   $a1 -  top  edge's y coordinate of the object of interest
#    $a2 - right edge's x coordinate of the object of interest,  $a3 - bottom edge's y coordinate of the object of interest
#    return : $v0 = 0 - no collision, $v0 = 1 - collision 
checkExtraBorderCollision:
  
  addi $sp, $sp -24
  sw $ra, 20($sp)
  
  # a0, a1, keep
  # put $a2 -> 12($sp) 
  # put $a3 -> 8($sp)
  # then we need to get the x-cooridnate $a2 of the border, and the right x 
  # which is x+400 4($sp)
  # y1 = 400 $a3
  # y2 = 450 it is constant 0($sp)
  sw $a2, 12($sp)
  sw $a3, 8($sp)
  
  la $t0, bonusXCoord
  lw $t1, 0($t0)
  move $a2, $t1  #now $a2 is the left x-coordinate of the border
  li $a3, 400 #now $a3 is the top y-coordinate of the border
  addi $t1, $t1, 400
  sw $t1, 4($sp) # save the right edge's x-coordiate to 4($sp)
  li $t1, 450
  sw $t1, 0($sp) # save the bottom y'coordiate to 0($sp)
  
  jal checkObjectCollision
   
  lw $ra, 20($sp)
  addi $sp, $sp, 24
 
  # return $v0: same value as checkObjectCollision
  jr $ra


#Function: check if a new food item does not overlap with the range of the sliding border
#in:  $a0 - y coordinate of the top-left corner of the food item;
#out: $v0 = 1 - does not overlap with the sliding border; $v0 = 0 - does overlap ==> cannot place food item
checkIfNewFoodItemOverlapExtraBorder:
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  
  la $t0, foodPicSize
  lw $t1, 4($t0)    #get the height of the food
  # y>450 or y<400-food_height
  li $t2, 450
  li $t3, 400
  sub $t3, $t3, $t1    #t3 = 400-food_height
  
  bgt $a0, 450, not_overlap
  blt $a0, $t3, not_overlap
  li $v0, 0
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr $ra
  
not_overlap:
  li $v0, 1
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr $ra
  
  
  
  
  
  
  # assume does not overlap
   
  
  

#Function: move the sliding border horizontally. The speed of the border is fixed and it's 4 pixels  
#          the speed must be a multiple of 800 (in out case it is 4)
moveSlidingBorder:

  addi $sp, $sp, -4
  sw $ra, 0($sp)
  
  la $t0, bonusXCoord #t0 is the address of the bonusXCord
  lw $t1, 0($t0) #get the x of the Border
  
  la $t2, bonusDirection #t2 is the address of the direction
  lw $t3, 0($t2) #get the direction of the Border
  
  beq $t3, 0, move_right
  #keep t0, t2
  beq $t3, -1, move_left

move_right:
  blt $t1, 400, keep_right
  j change_direction_to_left
 
keep_right:
  addi $t1, $t1, 4
  sw $t1, 0($t0)
  j move_end

change_direction_to_left:
  addi $t3, $zero, -1
  sw $t3, 0($t2)
  j keep_left
  
move_left:
  bgt $t1, 0, keep_left
  j change_direction_to_right
  
change_direction_to_right:
  addi $t3, $zero, 0
  sw $t3, 0($t2)
  j keep_right
  
keep_left:
  addi $t1, $t1, -4
  sw $t1, 0($t0)
  j move_end
  
move_end:
  
  jal addExtraBorder
   
  lw $ra, 0($sp)
  addi $sp, $sp, 4       
  jr $ra
  
  


  
        
###########################################################################################
#      BONUS PART ENDS HERE
###########################################################################################          
                        
    
    
 ###########################################################################################
#               Helper functions for testing
 ###########################################################################################
printTestMessage:
    li $v0, 4
    la $a0, testMSG
    syscall
    
    la $a0, newline
    syscall
    
    jr $ra

printObjectIDs:
    li $v0, 1
    
    ori $t4, $zero, 0
    
    la $t0, snakeBody
    
    ori $t1, $zero, 0
    addi $t2, $zero, 16
    
ids_loop:
    slt $t3, $t1, $t2
    beq $t3, $zero, end_main
    
    sll $t3, $t1, 4
    add $t3, $t3, $t0
    
    lw $a0, 0($t3)
     
    syscall
    
    addi $t1, $t1, 1
    j ids_loop
    
