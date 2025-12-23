library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity port_io is
    generic (
        base_addr : std_logic_vector(8 downto 0) := "000000000" 
    );
    port (
        nrst       : in  std_logic;
        clk_in     : in  std_logic;
        abus       : in  std_logic_vector(8 downto 0);
        io_en      : in  std_logic;
        r_nwr      : in  std_logic;
        dbus       : inout std_logic_vector(7 downto 0);
        port_io    : inout std_logic_vector(7 downto 0)
    );
end entity port_io;

architecture port_io_arch of port_io is

    signal dir_reg_int  : std_logic_vector(7 downto 0);
    signal port_reg_int : std_logic_vector(7 downto 0);
    signal latch_int    : std_logic_vector(7 downto 0);

    signal write_dir_reg  : std_logic;
    signal write_port_reg : std_logic;
    signal read_dir_reg   : std_logic;
    signal read_latch     : std_logic;

    constant DIR_REG_ADDR : std_logic_vector(8 downto 0) := std_logic_vector(unsigned(base_addr) + 1); 

begin

    -- Decodificação
    write_port_reg <= '1' when (abus = base_addr and io_en = '1' and r_nwr = '0') else '0';
    write_dir_reg  <= '1' when (abus = DIR_REG_ADDR and io_en = '1' and r_nwr = '0') else '0';
    read_latch     <= '1' when (abus = base_addr and io_en = '1' and r_nwr = '1') else '0';
    read_dir_reg   <= '1' when (abus = DIR_REG_ADDR and io_en = '1' and r_nwr = '1') else '0';

    -- =======================================================================
    -- 1. PROCESSO SÍNCRONO (Apenas para escrita nos registradores internos)
    -- =======================================================================
    process (clk_in, nrst)
    begin
        if nrst = '0' then 
            dir_reg_int <= (others => '0');
            port_reg_int <= (others => '0');
            -- O LATCH SAIU DAQUI!
        elsif rising_edge(clk_in) then
            if write_dir_reg = '1' then
                dir_reg_int <= dbus;
            end if;
            
            if write_port_reg = '1' then
                port_reg_int <= dbus;
            end if;
        end if;
    end process;


    process (read_latch, port_io)
    begin
        if read_latch = '0' then
            latch_int <= port_io;
        end if;
    end process;

    -- Controle do Tri-State do Barramento de Dados (Leitura pelo processador)
    dbus <= dir_reg_int when read_dir_reg = '1' else
            latch_int   when read_latch = '1'   else
            (others => 'Z');

    -- Controle dos Pinos Físicos (Tri-state de Saída)
    -- Se bit de direção for '1' (Saída), joga o valor. Se for '0' (Entrada), fica em 'Z'.
    port_io(7) <= port_reg_int(7) when dir_reg_int(7) = '1' else 'Z';
    port_io(6) <= port_reg_int(6) when dir_reg_int(6) = '1' else 'Z';
    port_io(5) <= port_reg_int(5) when dir_reg_int(5) = '1' else 'Z';
    port_io(4) <= port_reg_int(4) when dir_reg_int(4) = '1' else 'Z';
    port_io(3) <= port_reg_int(3) when dir_reg_int(3) = '1' else 'Z';
    port_io(2) <= port_reg_int(2) when dir_reg_int(2) = '1' else 'Z';
    port_io(1) <= port_reg_int(1) when dir_reg_int(1) = '1' else 'Z';
    port_io(0) <= port_reg_int(0) when dir_reg_int(0) = '1' else 'Z';

end architecture port_io_arch;