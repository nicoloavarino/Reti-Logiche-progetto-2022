

---------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nicolò Avarino
-- 
-- Create Date: 08.05.2022 16:44:31
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 10667140
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------



---------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nicolò Avarino
-- 
-- Create Date: 08.05.2022 16:44:31
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 10667140
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY project_reti_logiche is
	PORT
	(
		i_clk     : IN std_logic;
		i_rst     : IN std_logic; --viene sempre dato prima della prima elaborazione o durante il processo
		i_start   : IN std_logic; --da inizio all'elaborazione e rimane alto fino a che done non viene portato alto
		i_data    : IN std_logic_vector(7 DOWNTO 0);
		o_address : OUT std_logic_vector(15 DOWNTO 0);
		o_done    : OUT std_logic; --portato alto quando si finisce l'elaborazione
		o_en      : OUT std_logic := '0'; --memory enable
		o_we      : OUT std_logic; --write enable
		o_data    : OUT std_logic_vector (7 DOWNTO 0) --eventuale segnale da scrivere in memoria all'indirizzo o_address
	);
end project_reti_logiche;

ARCHITECTURE Behavioral OF project_reti_logiche is

	type stato is (WAIT_START,NUM_WORDS_TO_INT,ASK_REQUEST,WAIT_MEMORY,READ_REQUEST,UPDATE_ADDR,ASK_WORD,WAIT_CLOCK,READ_WORD,GET_BIT,CONTROLLER_CONVOLUTION,CONVOLUTION_0,CONVOLUTION_3,CONVOLUTION_1,CONVOLUTION_2,WRITE_P1k_ON_WORD_CONVOLUTED,WRITE_P2k_ON_WORD_CONVOLUTED,WRITE_WORD_1,UPDATE_OADDR,WRITE_WORD_2,UPDATE_OADDR2, DONE);
	SIGNAL next_state          : stato;
	SIGNAL curr_iaddress	   : std_logic_vector(15 DOWNTO 0);
	SIGNAL curr_oaddress       : std_logic_vector(15 DOWNTO 0);
	SIGNAL number_of_words_std,word_written		   : std_logic_vector(7 DOWNTO 0);
	SIGNAL word_convoluted	   : std_logic_vector(15 DOWNTO 0);
	SIGNAL number_of_words, i,k,convolution_node : integer range 0 to 255; 
	SIGNAL p1k       	   :  std_logic ;
	SIGNAL p2k       	   :  std_logic ;
	SIGNAL bit_analyzed    :  std_logic ;


			


begin

process (i_clk, i_rst)

begin
    IF i_rst = '1' THEN
			o_done     <= '0';
			next_state <= WAIT_START;
    ELSIF i_clk'event and i_clk = '1' THEN
        
        case next_state  is

        WHEN WAIT_START => --aspetto segnale di start
            o_done <= '0';
            o_we      <= '0';
            IF i_start = '1' THEN
                
                next_state  <= ASK_REQUEST;
            ELSE
                next_state <= WAIT_START;
            END IF;    

        WHEN ASK_REQUEST => --ask request
             o_en       <= '1';
             o_we       <= '0';
             convolution_node <= 0;
             curr_iaddress <= "0000000000000000"; --inizializzo indirizzo di input
             curr_oaddress <= "0000001111101000"; -- inizializzo indirizzo di output
             o_address  <= "0000000000000000";
             next_state <= WAIT_MEMORY;

        WHEN WAIT_MEMORY => -- wait memory
             
             o_we       <= '0';
             next_state <= READ_REQUEST;
         
        WHEN READ_REQUEST => --read request
             
             o_we       <= '0';
             number_of_words_std <= i_data; --salvo la richiesta in una variabile
             next_state   <= NUM_WORDS_TO_INT;
             
        WHEN NUM_WORDS_TO_INT =>
            o_done     <= '0';			
            o_we      <= '0';
            number_of_words <= to_integer(unsigned(number_of_words_std)); -- trasformo in intero
            next_state <= UPDATE_ADDR;

        WHEN UPDATE_ADDR => 
            o_done     <= '0';
            o_we      <= '0';
             curr_iaddress <= curr_iaddress + "0000000000000001"; 
             next_state <= ASK_WORD;


        WHEN ASK_WORD => -- ask parola
            
            IF number_of_words /= 0 THEN --se le parole non sono finite continuo a leggerle
             o_done     <= '0';
             o_en		<= '1';
             o_we		<= '0';
             i      	<= 7; -- inizializzo i = 7
             number_of_words <= number_of_words - 1;
             o_address 	<= curr_iaddress;
             next_state <= WAIT_CLOCK;
            ELSE	
            o_done     <= '0';
            o_we      <= '0';
             next_state <= DONE;		
            END IF;

        WHEN WAIT_CLOCK =>
             o_done     <= '0';
             o_we       <= '0';
             next_state <= READ_WORD;

        WHEN READ_WORD => --leggo parola
             o_done     <= '0';
             o_we       <= '0';
             word_convoluted <= "0000000000000000";
             k           <= 15;
             word_written <= i_data;  
             next_state <= GET_BIT;

        WHEN GET_BIT => --prendo un bit della parola e applico la convoluzione
        
            IF i < 0 THEN
            o_done     <= '0';			
            o_we      <= '0';
                next_state <= WRITE_WORD_1; --taglio la parola in due per poi scriverla in output		

            ELSE 
            o_done     <= '0';
            o_we      <= '0';
                bit_analyzed <= word_written(i); --prendo il bit i-esimo              
                
		        next_state <= CONTROLLER_CONVOLUTION;
            END IF;
         
        WHEN CONTROLLER_CONVOLUTION =>
            o_done     <= '0';
            o_we      <= '0';
            i <= i - 1 ; --decremento i e prendo bit successivo
            IF convolution_node = 0 THEN                
                    next_state <= CONVOLUTION_0;
            ELSIF convolution_node = 1 THEN               
                    next_state <= CONVOLUTION_1;  
            ELSIF convolution_node = 2 THEN               
                    next_state <= CONVOLUTION_2;
            ELSIF convolution_node = 3 THEN
                    next_state <= CONVOLUTION_3;
            END IF;      
  
        WHEN CONVOLUTION_0 => --se siamo nel nodo 0
            o_done     <= '0';
            o_we      <= '0';

            IF bit_analyzed = '0' THEN 
                p1k <= '0'; -- segnale da far uscire
                p2k <= '0'; -- segnale da far uscire
                convolution_node <= 0; --rimane nel nodo 0
               
            ELSE 
                p1k <= '1'; -- segnale da far uscire
                p2k <= '1'; -- segnale da far uscire
                convolution_node <= 1; --va al nodo 1
                
            END IF;
            next_state <= WRITE_P1k_ON_WORD_CONVOLUTED;

        WHEN CONVOLUTION_1 => --se siamo nel nodo 1
             o_done     <= '0';
            o_we      <= '0';

                IF bit_analyzed = '0' THEN 
                    p1k <= '0'; -- segnale da far uscire
                    p2k <= '1'; -- segnale da far uscire
                    convolution_node <= 3; --va nel nodo 3
                    
            
                ELSE
                    p1k <= '1'; -- segnale da far uscire
                    p2k <= '0'; -- segnale da far uscire
                    convolution_node <= 2; --va al nodo 2
                    
                END IF;
                next_state <= WRITE_P1k_ON_WORD_CONVOLUTED;

        WHEN CONVOLUTION_2 => --se siamo nel nodo 2
             o_done     <= '0';
                o_we      <= '0';
                                
                IF bit_analyzed = '0' THEN 
                    p1k <= '1'; -- segnale da far uscire
                    p2k <= '0'; -- segnale da far uscire
                    convolution_node <= 3; --va nel nodo 3
                    
                ELSE
                    p1k <= '0'; -- segnale da far uscire
                    p2k <= '1'; -- segnale da far uscire
                    convolution_node <= 2; --rimane al nodo 2
                    
                END IF;	
                next_state <= WRITE_P1k_ON_WORD_CONVOLUTED;

        WHEN CONVOLUTION_3 => --se siamo nel nodo 3
                o_done     <= '0';
                o_we      <= '0';


                IF bit_analyzed = '0' THEN 
                    p1k <= '1'; -- segnale da far uscire
                    p2k <= '1'; -- segnale da far uscire
                    convolution_node <= 0; --va nel nodo 0
                    
                ELSE
                    p1k <= '0'; -- segnale da far uscire
                    p2k <= '0'; -- segnale da far uscire
                    convolution_node <= 1; --va al nodo 1
                   
                END IF;
                next_state <= WRITE_P1k_ON_WORD_CONVOLUTED;

        

        WHEN WRITE_P1k_ON_WORD_CONVOLUTED => 
            o_done     <= '0';
            o_we      <= '0';
            word_convoluted(k) <= p1k;
            k <= k - 1;
            next_state <= WRITE_P2k_ON_WORD_CONVOLUTED;

        WHEN WRITE_P2k_ON_WORD_CONVOLUTED => 
            o_done     <= '0';
            o_we      <= '0';
            word_convoluted(k) <= p2k;
            k <= k - 1;
            next_state <= GET_BIT;

        WHEN WRITE_WORD_1 => -- scrivo la prima parola
            o_done     <= '0';
            o_en      <= '1';
            o_we      <= '1';
            o_address <= curr_oaddress;
            o_data <= word_convoluted(15 downto 8);
            next_state <= UPDATE_OADDR;
        
        WHEN UPDATE_OADDR => -- aggiorno indirizzo
            o_done     <= '0';
            o_we      <= '0';
            curr_oaddress <= curr_oaddress + "0000000000000001";
            next_state <= WRITE_WORD_2;
        
        WHEN WRITE_WORD_2 => --scrivo seconda parola
            o_done     <= '0';
            o_en      <= '1';
            o_we      <= '1';
            o_address <= curr_oaddress;
            o_data <= word_convoluted(7 downto 0);
            next_state <= UPDATE_OADDR2;
        
        WHEN UPDATE_OADDR2 => --aggiorno indirizzo
            o_done     <= '0';
            o_we      <= '0';
            curr_oaddress <= curr_oaddress + "0000000000000001";
            next_state <= UPDATE_ADDR; --chiedo una nuova parola 	
        
        WHEN DONE =>
            o_done <= '1';
            IF (i_start = '0') THEN
                next_state <= WAIT_START;
            ELSE
                next_state <= DONE;
            END IF;

    
        end case;
    end if;
end process;
end Behavioral;
