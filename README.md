# Processador 16-bit com Arquitetura Personalizada em VHDL

Projeto final desenvolvido para a disciplina de Arquitetura de Computadores do curso de **Engenharia de Computação** da **PUC Minas**. O projeto consiste na implementação completa de um processador de 16 bits, desde a definição do ISA (Instruction Set Architecture) até a síntese em FPGA.

## 👥 Autores
* **Bruno Henrique Freitas**
* **Oscar Oliveira Dias**

**Professor Orientador:** Francisco Manoel Pinto Garcia  
**Instituição:** Pontifícia Universidade Católica de Minas Gerais (PUC Minas)  
**Campus:** Coração Eucarístico - Belo Horizonte

---

## 🎯 Visão Geral
Este projeto implementa um processador *soft-core* utilizando VHDL. O sistema foi projetado com uma arquitetura baseada em barramento, capaz de executar instruções lógicas, aritméticas, de desvio e de manipulação de memória/IO.

O sistema foi validado via simulação (ModelSim) e implementado fisicamente em um kit de desenvolvimento FPGA **Altera DE2** (Cyclone II).

### 🛠️ Tecnologias Utilizadas
* **Linguagem:** VHDL (IEEE 1164 / Numeric Std)
* **IDE:** Quartus II
* **Simulação:** ModelSim Altera
* **Hardware:** Kit FPGA Altera DE2
* **Memória:** Arquitetura Harvard Modificada (ROM para programa, RAM para dados)

---

## 🏗️ Arquitetura do Sistema

O processador é composto pelos seguintes blocos principais:

1.  **Unidade de Controle (FSM):** Máquina de estados finitos que gerencia o ciclo de busca (Fetch), decodificação e execução. Suporta instruções de ciclo único e instruções de múltiplos ciclos (ex: Jumps e Calls).
2.  **Datapath:**
    * **Banco de Registradores:** 4 registradores de propósito geral (R0-R3) de 8 bits.
    * **ULA (ALU):** Unidade Lógica e Aritmética capaz de realizar 16 operações (Soma, Subtração, AND, OR, XOR, NOT, Shifts e Rotates).
    * **PC e Stack:** Contador de programa com suporte a sub-rotinas (Pilha de hardware para CALL/RET).
3.  **Sistema de I/O:**
    * Portas bidirecionais mapeadas em memória.
    * Controle de direção (Input/Output) via registradores de configuração.
    * Implementação de *Latches* transparentes para estabilização de leitura externa.

![Diagrama de Blocos](Diagrama.pdf)


---

## 📝 Conjunto de Instruções (ISA)

O processador utiliza instruções de tamanho fixo (16 bits). A decodificação utiliza bits de "Grupo" e um "Bit Auxiliar" (Bit 8) para expandir a capacidade da ULA.

### Formatos Principais:

| Bits 15-14 (Grupo) | Tipo de Instrução | Descrição |
| :--- | :--- | :--- |
| **00** | **Reg-Reg** | Operações entre dois registradores (ADD, SUB, AND...) |
| **01** | **Imediato/Shift** | Operações com constante ou Deslocamentos (SLL, ROR...) |
| **10** | **Memória/IO** | Acesso à RAM e Portas (LDM, STM, INP, OUT) |
| **11** | **Controle de Fluxo** | Desvios e Sub-rotinas (JMP, JZ, CALL, RET) |

### Destaque da Implementação (Bit 8)
Para permitir 16 operações na ULA utilizando apenas 3 bits de opcode na instrução, implementamos uma lógica de decodificação baseada no **Bit 8**:
* Se Bit 8 = '0' no Grupo 01: Executa operação com Imediato (ex: ADDI).
* Se Bit 8 = '1' no Grupo 01: Executa operação de Shift/Rotate (ex: SLL, ROR).

---

## 🧪 Demonstração e Testes

Para validar o processador, desenvolvemos um programa em Assembly ("Running LED") que demonstra o uso de:
* Configuração de portas de I/O (Entrada para chaves, Saída para LEDs).
* Chamada de sub-rotinas (CALL/RET) para gerar atraso (Delay).
* Instruções de Rotação (RL/RR) para criar o efeito de anel.
* Leitura de botões para alteração de fluxo em tempo real.

### Funcionamento:
1.  O sistema inicia com um LED aceso.
2.  O processador lê o estado da chave na **Porta B**.
3.  Se a chave for **0**: O LED rotaciona para a **Esquerda**.
4.  Se a chave for **1**: O LED rotaciona para a **Direita**.

### Vídeo de Funcionamento no FPGA
https://github.com/user-attachments/assets/669237f8-2cae-4e97-9ef1-a9e387253a78


---

## 🚀 Como Executar

1.  Abra o projeto no **Quartus II**.
2.  Compile o projeto para verificar a integridade do hardware.
3.  Carregue o arquivo `.mif` desejado na memória ROM.
4.  Para simulação: Utilize o **ModelSim** com o testbench fornecido.
5.  Para FPGA: Atribua os pinos (Pin Planner) de acordo com o manual da placa DE2 e utilize o **Programmer** para enviar o `.sof`.

---


Feito com ☕ e VHDL por Bruno e Oscar.

