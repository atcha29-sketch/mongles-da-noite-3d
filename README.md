# Mongles da Noite

Sobreviva a uma noite de criaturas em um roguelite de ação com personagens em pixel art. Escolha um herói, enfrente monstros, colete fragmentos de alma e evolua para resistir cada vez mais.

## Classes

- **Guerreiro:** mais vida e um giro de espada em 360° que atinge vários inimigos.
- **Mago:** menos vida, mas orbes arcanos explodem causando dano em área.
- **Arqueiro:** mais velocidade, flechas perfurantes e maior alcance.
- **Lango:** mago necromante que invoca esqueletos para perseguir e atacar criaturas.
- **Kalengue:** maga invocadora que chama gatos de várias cores para dar botes nos inimigos.
- **Bronha Man:** caubói com duas pistolas douradas, disparos rápidos e rajadas que crescem com seus upgrades.

Cada subida de nível oferece uma melhoria exclusiva da classe escolhida junto
com poderes elementais. O guerreiro pode ampliar o giro, fortalecer a lâmina
ou endurecer a pele; o mago pode ampliar explosões, fortalecer orbes ou acelerar
as magias; o arqueiro pode perfurar mais alvos, usar um arco longo ou disparar
mais flechas; Lango pode aumentar seu bando de esqueletos e fortalecer suas
garras; Kalengue pode chamar mais gatos e melhorar seus botes. Com os upgrades
de quantidade, cada invocador pode ter até oito aliados. Eles têm vida, podem
ser derrotados e são invocados novamente; durante os chefes, priorizam o ataque
ao chefe. Os ataques também recebem o brilho e os efeitos do elemento ativo.
Cada classe tem animações, efeitos sonoros e melhorias próprios.

Na apresentação da história, pressione **Espaço** ou clique em **Conheça os
heróis** para abrir a seleção. Clique na carta ou pressione **1** a **6** para
escolher uma classe. Após uma derrota, use **Escolher outra
classe** para trocar de herói.

## Controles

| Tecla | Ação |
| --- | --- |
| WASD / setas | Mover |
| Espaço | Começar / retomar |
| Esc | Pausar / continuar |
| ? | Mostrar controles |
| M | Ligar / desligar os efeitos sonoros |
| 1 / 2 / 3 / 4 / 5 / 6 | Na tela inicial: escolher classe; ao subir de nível: escolher poder (1–3) |
| Q | Sair |

Controles compatíveis são detectados diretamente pelo SDL2 no Linux, sem
depender da Steam: analógico esquerdo move, direcional ou LB/RB navegam nas
opções, **A** confirma e **B/Start** pausa ou continua. Steam Input é opcional
e serve apenas para remapear botões; no Steam Deck, o jogo também pode ser
iniciado fora da Steam. Teclado e mouse continuam disponíveis.

Cada nível oferece três poderes: **Fogo** queima inimigos, **Gelo** desacelera
criaturas, **Raio** salta entre monstros próximos e **Sombra** atravessa os
inimigos. Os efeitos sonoros originais acompanham disparos, impactos, coleta,
ferimentos e melhorias.

Os efeitos WAV inclusos podem ser recriados com `python assets/generate_sfx.py`;
as trilhas originais de cada estágio e de cada chefe com
`python assets/generate_music.py`.

## Estágios e chefes

A noite atravessa quatro cenários temáticos: **Beco dos Noias**, **Quintal dos
Noiados**, **Pedreira da Meia Noite** e **Surubão Central**. Cada estágio tem
um subchefe próprio aos 20 segundos e, aos 40 segundos, o chefe principal:
**O Mestre do Beco**, **O Espantalho Noiado**, **A Pedra Fumegante** e **O Rei
da Pista**. Subchefes e chefes disparam raios com um breve aviso visual para
que o jogador possa desviar. Ao vencer o Surubão Central, a jornada recomeça
mais difícil; depois da terceira conclusão, abre-se o **Vale das Carcaças**.
Esse quinto estágio também tem criaturas e subchefe antes da luta contra o
chefe gigante **A Carcaça da Meia Noite**. Na luta final, a Carcaça cria ecos
que cercam o jogador e podem ser derrotados.

Uma fenda aberta à meia-noite despertou os mortos e corrompeu os quatro
bairros. Vença três noites completas para descobrir que a própria ruptura
ganhou corpo no Vale. As telas de transição contam a história de cada estágio.

Criaturas podem deixar itens: o bônus verde aumenta a velocidade, o azul
aumenta a cadência de disparo por 12 segundos e o item vermelho amaldiçoado
invoca uma super-horda.

## Construir e testar

```sh
./bin/build
./bin/test
```

Na build desktop o jogo usa Vulkan por padrão. Se o driver não suportar Vulkan,
inicie com OpenGL:

```sh
./build/mongles-da-noite --vulkan
./build/mongles-da-noite --opengl
```

Vulkan acelera a cena Qt Quick e a renderização 3D. A versão WebAssembly usa
WebGL 2 do navegador; Vulkan nativo não está disponível nesse alvo.

## WebAssembly

O build para navegador usa Qt 6.12 `wasm_singlethread` e Emscripten 5.0.5.
O módulo Qt Multimedia precisa estar compilado para esse kit para habilitar os
efeitos sonoros e a música. Com os SDKs instalados em `~/Qt/6.12.0` e
`~/emsdk`, gere a versão web com:

```sh
./bin/build-wasm
cd build/wasm
python3 -m http.server 8000
```

Abra `http://localhost:8000/mongles-da-noite.html` no navegador. Para outros
caminhos de instalação, defina `QT_WASM_ROOT` e `EMSDK_DIR` antes de executar
`bin/build-wasm`.

Para criar e instalar o pacote do Arch:

```sh
./bin/install
```
