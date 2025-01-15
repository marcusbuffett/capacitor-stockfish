#include <iostream>
#include "../../stockfish/src/bitboard.h"
#include "../../stockfish/src/misc.h"
#include "../../stockfish/src/position.h"
#include "../../stockfish/src/types.h"
#include "../../stockfish/src/uci.h"
#include "../../stockfish/src/tune.h"
#include "../../lib/threadbuf.h"
#include "Stockfish.hpp"
#include "StockfishSendOutput.h"

namespace CapacitorStockfish {
  using namespace Stockfish;
  static std::string CMD_EXIT = "stockfish:exit";
  static UCIEngine* uci = nullptr;

  auto readstdout = [](void *bridge) {
    std::streambuf* out = std::cout.rdbuf();

    threadbuf lichbuf(8, 8096);
    std::ostream lichout(&lichbuf);
    std::cout.rdbuf(lichout.rdbuf());
    std::istream lichin(&lichbuf);

    std::string o = "";

    while (o != CMD_EXIT) {
      std::string line;
      std::getline(lichin, line);
      if (line != CMD_EXIT) {
        const char* coutput = line.c_str();
        StockfishSendOutput(bridge, coutput);
      } else {
        o = CMD_EXIT;
      }
    };

    std::cout.rdbuf(out);
    lichbuf.close();
  };

  std::thread reader;

  void init(void *bridge) {
    std::cout << engine_info() << std::endl;
    
    reader = std::thread(readstdout, bridge);

    Bitboards::init();
    Position::init();

    // Create UCI engine with no command line arguments
      char* argv[] = {const_cast<char*>("stockfish")};  // Program name as first arg
      uci = new UCIEngine(0, argv);
  }

  void cmd(std::string cmd) {
      using namespace Stockfish;
      uci->command(cmd);
  }

  void exit() {
      uci->command("quit");
    sync_cout << CMD_EXIT << sync_endl;
    reader.join();
    if (uci) {
        delete uci;
        uci = nullptr;
    }
  }
}
