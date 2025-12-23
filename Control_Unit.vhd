LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Control_Unit IS
    PORT (
        -- Entradas de Controle
        clk           : IN  STD_LOGIC;
        nrst          : IN  STD_LOGIC;
        
        -- Entradas de Dados/Status (provenientes do IR e do Satus_reg
        opcode        : IN  STD_LOGIC_VECTOR(15 DOWNTO 8);
        c_flag        : IN  STD_LOGIC;
        z_flag        : IN  STD_LOGIC;
        v_flag        : IN  STD_LOGIC;

        -- Saídas de Controle do Datapath
        reg_a_on_dbus : OUT STD_LOGIC; -- Habilita o RegA no barramento
        alu_on_dbus   : OUT STD_LOGIC; -- 0=ALU, 1=Memória/IO para o DBUS
        alu_bin_sel   : OUT STD_LOGIC; -- seleciona operando B da Alu
        reg_wr_ena    : OUT STD_LOGIC; -- Habilita escrita no banco de registradores
        
        c_flag_wr_ena : OUT STD_LOGIC; -- Habilita atualização do Carry
        z_flag_wr_ena : OUT STD_LOGIC; -- Habilita atualização do Zero
        v_flag_wr_ena : OUT STD_LOGIC; -- Habilita a atualização do Obverflow
        
        alu_op        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- Operação da ULA
        
        stack_push    : OUT STD_LOGIC; -- Empilha o PC
        stack_pop     : OUT STD_LOGIC; -- Desemplilha o PC
        pc_ctrl       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- Controle do PC(Inc, Jump, etc)
        
        mem_en        : OUT STD_LOGIC; -- Habilita mémoria de dados (RAM)
        io_en         : OUT STD_LOGIC; -- Habilita os blocos de Entrada/saida
        r_nwr         : OUT STD_LOGIC -- Sinal de leitura (1) escrita (0)
    );
END ENTITY Control_Unit;

ARCHITECTURE Behavioral OF Control_Unit IS

    -- Máquina de estados com 3 estados para otimização de ciclos
    -- RESET: Estado de inicialização do sistema
    -- FETCH_EXEC: Ciclo único para ALU, Memória e I/O
    -- JUMP_WAIT: Segundo ciclo exclusivo para instruções de desvio (JMP, CALL, RET, etc)
    TYPE state_type IS (reset, fetch_exec, jump_wait);
    SIGNAL pres_state, next_state : state_type;

BEGIN

    -- =======================================================================
    -- PROCESSO SEQUENCIAL: MEMÓRIA DE ESTADO
    -- Responsável pela transição de estados na borda do clock
    -- =======================================================================
    PROCESS(clk, nrst)
    BEGIN
        IF nrst = '0' THEN
            pres_state <= reset; -- Reset limpa a máquina para o estado inicial
        ELSIF rising_edge(clk) THEN
            pres_state <= next_state; -- Transição síncrona
        END IF;
    END PROCESS;

    -- =======================================================================
    -- PROCESSO COMBINACIONAL: Lógica de Próximo Estado e Saídas
    -- Define o que cada pino fará baseado no estado e no opcode
    -- =======================================================================
    PROCESS(pres_state, opcode, z_flag, c_flag, v_flag)
    BEGIN
        -- -------------------------------------------------------------------
        -- 1. Definição de Valores Padrão (Defaults)
        -- Importante para evitar inferência de Latches acidentais
        -- -------------------------------------------------------------------
        next_state    <= fetch_exec;
        
        pc_ctrl       <= "00"; -- PC em Hold

        reg_a_on_dbus <= '0';
        alu_on_dbus   <= '0'; -- Padrão: 0 (Seleciona ULA)
        alu_bin_sel   <= '0';
        reg_wr_ena    <= '0';

        c_flag_wr_ena <= '0';
        z_flag_wr_ena <= '0';
        v_flag_wr_ena <= '0';

        alu_op        <= "0000";

        stack_push    <= '0';
        stack_pop     <= '0';
        

        mem_en        <= '0';
        io_en         <= '0';
        r_nwr         <= '1'; -- Padrão: Leitura

        -- -------------------------------------------------------------------
        -- 2. Máquina de Estados
        -- -------------------------------------------------------------------
        CASE pres_state IS

            WHEN reset =>
----                next_state <= fetch_exec;
                next_state <= jump_wait;
                pc_ctrl    <= "00";

            -- ESTADO PRINCIPAL (Ciclo Único para a maioria das instruções)
            WHEN fetch_exec =>
                CASE opcode(15 DOWNTO 14) IS
                    -- GRUPO 00/01: OPERAÇÕES DE ULA
					WHEN "00" | "01" =>
						next_state    <= fetch_exec;
						pc_ctrl       <= "01";
						reg_wr_ena    <= '1';
						alu_on_dbus   <= '1';
						z_flag_wr_ena <= '1';
						c_flag_wr_ena <= '1';

						-- Se for Grupo 01 E o bit 8 for '1', é Shift/Not (ULA 8 a 15)
						IF opcode(15 downto 14) = "01" AND opcode(8) = '1' THEN
							alu_op <= '1' & opcode(13 DOWNTO 11); -- Gera 1xxx (SLL, NOT, ROR...)
							alu_bin_sel <= '0'; -- Ignora imediato
							v_flag_wr_ena <= '0';
						
						ELSE
							-- Caso contrário (Reg-Reg ou Imediato normal), é ULA 0 a 7
							alu_op <= '0' & opcode(13 DOWNTO 11); -- Gera 0xxx (ADD, AND, MOV...)
							
							-- Controle do Mux B (Imediato vs Registrador)
							IF opcode(14) = '1' AND opcode(8) = '0' THEN
								alu_bin_sel <= '1'; -- Usa Imediato
								v_flag_wr_ena <= opcode(13);
							ELSE
								alu_bin_sel <= '0'; -- Usa Reg B
								v_flag_wr_ena <= opcode(13);
							END IF;
						END IF;

                    -- GRUPO 10: MEMÓRIA E I/O
                    WHEN "10" =>
                        next_state <= fetch_exec;
                        pc_ctrl    <= "01";
                        CASE opcode(13 downto 12) IS
							-- LDM  (00)  RAM -> RA
							WHEN "00" =>
								mem_en         <= '1';
								r_nwr          <= '1';
								reg_wr_ena     <= '1';
--								reg_a_on_dbus  <= '0';
--								alu_on_dbus    <= '1';

							-- STM  (01)  RA -> RAM
							WHEN "01" =>
								mem_en         <= '1';
								r_nwr          <= '0';
								reg_wr_ena     <= '0';
								reg_a_on_dbus  <= '1';   -- RA dirige DBUS
--								alu_on_dbus    <= '0';

							-- INP  (10)  PORT -> RA
							WHEN "10" =>
								io_en 		   <= '1';
								r_nwr          <= '1';
								reg_wr_ena     <= '1';
								reg_a_on_dbus  <= '0';
--								alu_on_dbus    <= '1';

							-- OUT  (11)  RA -> PORT
							WHEN "11" =>
								io_en          <= '1';
								r_nwr          <= '0';
								reg_wr_ena     <= '0';
								reg_a_on_dbus  <= '1';
--								alu_on_dbus    <= '0';
								
								alu_op        <= "0000";
								alu_bin_sel   <= '0';

							WHEN OTHERS =>
								NULL;

						END CASE;

                    -- GRUPO 11: DESVIOS, CALL, RET E NOP
                    WHEN "11" =>
                        IF opcode(13 DOWNTO 11) = "111" THEN -- NOP
                            next_state <= fetch_exec;
                            pc_ctrl    <= "01";
                        ELSE
                            -- Instruções de desvio exigem 2 ciclos
                            --next_state <= jump_wait;
                            pc_ctrl    <= "00"; -- Aguarda decisão no próximo ciclo
							CASE opcode(13 DOWNTO 11) IS
								WHEN "000" =>  -- JMP
									pc_ctrl <= "11";
									next_state <= jump_wait;

								WHEN "001" =>  -- JC
									IF c_flag = '1' THEN
										pc_ctrl <= "11";
										next_state <= jump_wait;
									ELSE
										pc_ctrl <= "01";
									END IF;

								WHEN "010" =>  -- JZ
									IF z_flag = '1' THEN
										pc_ctrl <= "11";
										next_state <= jump_wait;
									ELSE
										pc_ctrl <= "01";
									END IF;

								WHEN "011" =>  -- JV
									IF v_flag = '1' THEN
										pc_ctrl <= "11";
										next_state <= jump_wait;
									ELSE
										pc_ctrl <= "01";
									END IF;

								WHEN "100" =>  -- CALL
									stack_push <= '1';
									pc_ctrl    <= "11";
									next_state <= jump_wait;

								WHEN "101" =>  -- RET
									stack_pop <= '1';
									pc_ctrl   <= "10";
									next_state <= jump_wait;

								WHEN OTHERS =>
									pc_ctrl <= "01";
									next_state <= fetch_exec;
							END CASE;
                        END IF;

                    WHEN OTHERS => NULL;
                END CASE;

            -- SEGUNDO CICLO (Apenas para Desvios)
            WHEN jump_wait =>
                next_state <= fetch_exec; -- Retorna ao ciclo de busca normal
                pc_ctrl <= "01";		-- incrementa PC
--                CASE opcode(13 DOWNTO 11) IS
--					WHEN "101" => pc_ctrl <= "10"; stack_pop <= '1'; -- RET
--					WHEN OTHERS => pc_ctrl <= "11";                  -- JMP/CALL/Condicionais True
--				END CASE;
                

        END CASE;
    END PROCESS;

END ARCHITECTURE Behavioral;