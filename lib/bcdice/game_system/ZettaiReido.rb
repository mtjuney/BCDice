# frozen_string_literal: true

module BCDice
  module GameSystem
    class ZettaiReido < Base
      # ゲームシステムの識別子
      ID = 'ZettaiReido'

      # ゲームシステム名
      NAME = '絶対隷奴'

      # ゲームシステム名の読みがな
      SORT_KEY = 'せつたいれいと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        m-2DR+n>=x
        m(基本能力),n(修正値),x(目標値)
        DPの取得の有無も表示されます。
      INFO_MESSAGE_TEXT

      register_prefix('\d+\-2DR.*')

      def eval_game_system_specific_command(command)
        return nil unless command =~ /^(\d+)-2DR([+\-\d]*)(>=(\d+))?$/i

        baseAvility = Regexp.last_match(1).to_i
        modText = Regexp.last_match(2)
        diffValue = Regexp.last_match(4)

        return roll2DR(baseAvility, modText, diffValue)
      end

      def roll2DR(baseAvility, modText, diffValue)
        diceTotal, diceText, darkPoint = roll2DarkDice()

        mod, modText = getModInfo(modText)
        diff, diffText = getDiffInfo(diffValue)

        output = ""
        output += "(#{baseAvility}-2DR#{modText}#{diffText})"
        output += " ＞ #{baseAvility}-#{diceTotal}[#{diceText}]#{modText}"

        total = baseAvility - diceTotal + mod
        output += " ＞ #{total}"

        successText = getSuccessText(diceTotal, total, diff)
        output += successText

        darkPointText = getDarkPointResult(total, diff, darkPoint)
        output += darkPointText

        return output
      end

      def roll2DarkDice()
        dice1 = @randomizer.roll_once(6)
        dice2 = @randomizer.roll_once(6)

        darkDice1, darkPoint1 = changeDiceToDarkDice(dice1)
        darkDice2, darkPoint2 = changeDiceToDarkDice(dice2)

        darkPoint = darkPoint1 + darkPoint2
        if darkPoint == 2
          darkPoint = 4
        end

        darkTotal = darkDice1 + darkDice2
        darkDiceText = "#{darkDice1},#{darkDice2}"

        return darkTotal, darkDiceText, darkPoint
      end

      def changeDiceToDarkDice(dice)
        darkPoint = 0
        darkDice = dice
        if dice == 6
          darkDice = 0
          darkPoint = 1
        end

        return darkDice, darkPoint
      end

      def getModInfo(modText)
        value = ArithmeticEvaluator.eval(modText)

        text = ""
        if value < 0
          text = value.to_s
        elsif  value > 0
          text = "+" + value.to_s
        end

        return value, text
      end

      def getDiffInfo(diffValue)
        diffText = ""

        unless diffValue.nil?
          diffValue = diffValue.to_i
          diffText = ">=#{diffValue.to_i}"
        end

        return diffValue, diffText
      end

      def getDarkPointResult(_total, _diff, darkPoint)
        text = ''

        if darkPoint > 0
          text = " ＞ #{darkPoint}DP"
        end

        return text
      end

      def getSuccessText(diceTotal, total, diff)
        if diceTotal == 0
          return " ＞ クリティカル"
        end

        if diceTotal == 10
          return " ＞ ファンブル"
        end

        if diff.nil?
          diff = 0
        end

        successLevel = (total - diff)
        if successLevel >= 0
          return " ＞ #{successLevel} 成功"
        end

        return ' ＞ 失敗'
      end
    end
  end
end
