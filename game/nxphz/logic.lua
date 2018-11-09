
local utils = require "utils"
local define = require "define"
local CardData = require "CardData"
local AnswerData = require "AnswerData"
local KeyData = require "KeyData"

local M = {}

M.__index = M

function M.new(...)
    local o = {}
    setmetatable(o, M)

    M.init(o, ...)
    return o
end

-- ��ʼ��
function M:init()
    self.answerDataMax = AnswerData.new()

    -- �з�˳��
	-- һ����	 1 2 3		����ʮ		 2 7 10
    self.tFenShun =
    {
        {11, 12, 13, define.HUXI_123_B},			-- 	0x11, 0x12, 0x13,
		{12, 17, 20, define.HUXI_27A_B},			-- 	0x12, 0x17, 0x1A,
		{1,  2,  3,  define.HUXI_123_S},			-- 	0x01, 0x02, 0x03,
		{2,  7,  10, define.HUXI_27A_S},			-- 	0x02, 0x07, 0x0A,
    }
end

-- ��ȡ���ƽ��
function M:getCardHuResult(cardData, answerData, nFlag)
	if cardData.nAllCount%3 == 1 then
		return
    end

	if cardData.nAllCount == 0 then
		local nMaxValue = self.answerDataMax:getValue()
		if nMaxValue == 0 or nMaxValue < answerData:getValue() then
            self.answerDataMax.nHuXi = answerData.nHuXi
            self.answerDataMax.tKeyData = utils.copy_table(answerData.tKeyData)
        end
	elseif cardData.nAllCount == 2 then
		for i=1, define.MAX_CARD do
            local nCardCount = cardData.tCardData[i]
			if nCardCount == 2 then
				local nMaxValue = self.answerDataMax:getValue()
				if nMaxValue == 0 or nMaxValue < answerData:getValue() then
					self.answerDataMax.nHuXi = answerData.nHuXi
                    self.answerDataMax.tKeyData = utils.copy_table(answerData.tKeyData)
                    local info =
                    {
                        nHuXi = 0,
                        nType = define.ACK_NULL,
                        tCardData =
                        {
                            i,
                            i,
                        },
                    }
                    local keyData = KeyData.new(info)
					self.answerDataMax:push(keyData)
                end
			elseif nCardCount > 0 then
				break
            end
		end
	else
		local nType = math.modf(nFlag/define.MAX_ANALY_NUM)
		local nIndex = math.fmod(nFlag, define.MAX_ANALY_NUM)

		-- ��
		if nType <= define.ANALYTYPE_PENG then
		    for n=1, define.MAX_CARD do
                local nCardCount = cardData.tCardData[n]
			    if nCardCount >= 3 then
                    local info =
                    {
                        nHuXi = n>10 and define.HUXI_PENG_B or define.HUXI_PENG_S,
                        nType = define.ACK_PENG,
                        tCardData =
                        {
                            n,
                            n,
                            n,
                        },
                    }
                    local keyData = KeyData.new(info)
				    answerData:push(keyData)
				    cardData:pop(keyData)
				    self:getCardHuResult(cardData, answerData, define.ANALYTYPE_PENG*define.MAX_ANALY_NUM + n)
				    cardData:push(keyData)
				    answerData:pop()
				    break
                end
		    end
        end

		-- �з�˳��
		if nType <= define.ANALYTYPE_FENSHUN then
			if nType < define.ANALYTYPE_FENSHUN then
                nIndex = 1
            end
			for i=nIndex, 4 do
				local nNum1 = cardData.tCardData[self.tFenShun[i][1]]
				local nNum2 = cardData.tCardData[self.tFenShun[i][2]]
				local nNum3 = cardData.tCardData[self.tFenShun[i][3]]
				if nNum1 > 0 and nNum2 > 0 and nNum3 > 0 then
                    local info =
                    {
                        nHuXi = self.tFenShun[i][4],
                        nType = define.ACK_CHI,
                        tCardData =
                        {
                            self.tFenShun[i][1],
                            self.tFenShun[i][2],
                            self.tFenShun[i][3],
                        },
                    }
                    local keyData = KeyData.new(info)
					answerData:push(keyData)
					cardData:pop(keyData)
					self:getCardHuResult(cardData, answerData, define.ANALYTYPE_FENSHUN*define.MAX_ANALY_NUM + i)
					cardData:push(keyData)
					answerData:pop()
				end
			end
		end

		local nHuVal = answerData.nHuXi
		if nHuVal < define.MIN_HU_XI or self.answerDataMax.nHuXi >= nHuVal then
			return
        end

		-- �޷�˳��
		if nType <= define.ANALYTYPE_SHUN then
			if nType < define.ANALYTYPE_SHUN then
                nIndex = 0
            end

			local nCor	= math.modf(nIndex/10)
			local nValue = math.fmod(nIndex, 10)
			for i=nCor, 1 do
                if i > nCor then
                    nValue = 1
                end
				for j=nValue, 8 do
					local nNum1 = cardData.tCardData[i*10 + j]
					local nNum2 = cardData.tCardData[i*10 + j + 1]
					local nNum3 = cardData.tCardData[i*10 + j + 2]
					if nNum1 > 0 and nNum2 > 0 and nNum3 > 0 then
                        local info =
                        {
                            nHuXi = 0,
                            nType = define.ACK_CHI,
                            tCardData =
                            {
                                i*10 + j,
                                i*10 + j + 1,
                                i*10 + j + 2,
                            },
                        }
                        local keyData = KeyData.new(info)
						answerData:push(keyData)
						cardData:pop(keyData)
						self:getCardHuResult(cardData, answerData, define.ANALYTYPE_SHUN*define.MAX_ANALY_NUM + i*10 + j)
						cardData:push(keyData)
						answerData:pop()
					end
				end
			end
		end

        -- ��С��
		if nType <= define.ANALYTYPE_DXD then
			if nType < define.ANALYTYPE_DXD then
                nIndex = 1
            end

			-- ��С��
            for i = nIndex, 10 do
				local nNum1 = cardData.tCardData[10 + i]
				local nNum2 = cardData.tCardData[i]
				if nNum1 + nNum2 == 3 then
                    local info =
                    {
                        nHuXi = 0,
                        nType = define.ACK_CHI,
                        tCardData =
                        {
                            i,
                            i,
                            10 + i,
                        },
                    }
                    local keyData = KeyData.new(info)
					answerData:push(keyData)
					cardData:pop(keyData)
					self:getCardHuResult(cardData, answerData, define.ANALYTYPE_DXD*define.MAX_ANALY_NUM + i)
					cardData:push(keyData)
					answerData:pop()
				elseif nNum1 == 1 or nNum2 == 1 or nNum1 + nNum2 == 4 then
					break
                end
			end
		end
	end
end

-- ��ʼ������
function M:initCardHu(cardData, answerData, tHuCardInfo)
	-- �Լ����ƣ�ֱ�Ӳ���
	if tHuCardInfo.bSelf and tHuCardInfo.nInsertCard ~= 0 then
		cardData:addVal(tHuCardInfo.nInsertCard)
    end

	-- �����ó�4,3����
	for i=1, define.MAX_CARD do
		if cardData.tCardData[i] == 4 then
            local info =
            {
                nHuXi = i>10 and define.HUXI_TI_B or define.HUXI_TI_S,
                nType = define.ACK_TI,
                tCardData =
                {
                    i,
                    i,
                    i,
                    i,
                },
            }
            local keyData = KeyData.new(info)
			answerData:push(keyData)
			cardData:pop(keyData)
		elseif cardData.tCardData[i] == 3 then
            local info =
            {
                nHuXi = i>10 and define.HUXI_WEI_B or define.HUXI_WEI_S,
                nType = define.ACK_WEI,
                tCardData =
                {
                    i,
                    i,
                    i,
                },
            }
            local keyData = KeyData.new(info)
			answerData:push(keyData)
			cardData:pop(keyData)
		end
	end

	-- �����Լ�����
	if not tHuCardInfo.bSelf and tHuCardInfo.nInsertCard ~= 0 then
		cardData:addVal(tHuCardInfo.nInsertCard)
	end
	self:getCardHuResult(cardData, answerData, 0)
    answerData.nHuXi = self.answerDataMax.nHuXi
    answerData.tKeyData = utils.copy_table(self.answerDataMax.tKeyData)

	if #self.answerDataMax.tKeyData == define.MAX_WEAVE then
		return self.answerDataMax:getValue() > 0
	else
		return false
    end
end

function M:getHuCardInfo(tHuCardInfo)
    local cardData = CardData.new(tHuCardInfo.tCardData)
    local answerData = AnswerData.new()
    return self:initCardHu(cardData, answerData, tHuCardInfo)
end

-- ����
function M:shuffle(tCardData)
    local nCardCount = #tCardData
    for i=1, nCardCount do
        local j = math.random(i, nCardCount)
        if j > i then
            tCardData[i], tCardData[j] = tCardData[j], tCardData[i]
        end
    end
end

-- �Ƿ���Ч�˿�
function M:isValidCard(nCardData)
    return nCardData >= 1 and nCardData <= define.MAX_CARD
end

-- �˿���Ŀ
function M:getCardCount(tCardData)
    local nCount = 0
    for _, v in pairs(tCardData) do
        nCount = nCount + v
    end
    return nCount
end

-- ���ɾ���˿�
function M:checkRemoveCard(tCardData, tRemoveCard)
    local tTempCardData = {}
    for k, v in ipairs(tCardData) do
        tTempCardData[k] = v
    end

    local nDeleteCount = 0
    -- �����˿�
    for _, nCardData in ipairs(tRemoveCard) do
        if tTempCardData[nCardData] > 0 then
            nDeleteCount = nDeleteCount + 1
            tTempCardData[nCardData] = tTempCardData[nCardData] - 1
        else
            return false    -- ����ֱ�ӷ���false
        end
    end

    return nDeleteCount == #tRemoveCard
end

-- ɾ���˿�
function M:removeCard(tCardData, tRemoveCard)
    for _, nCardData in ipairs(tRemoveCard) do
        if tCardData[nCardData] > 0 then
            tCardData[nCardData] = tCardData[nCardData] - 1
        end
    end
end

-- �����ж�
function M:getAcitonTiCard(tCardData)
    local r = {}
    for i=1, define.MAX_CARD do
        if tCardData[i] == 4 then
            table.insert(r, i)
        end
    end

    return r
end

-- η���ж�
function M:getActionWeiCard(tCardData)
    local r = {}
    for i=1, define.MAX_CARD do
        if tCardData[i] == 3 then
            table.insert(r, i)
        end
    end

    return r
end

-- �����ж�
function M:getActionChiCard(tCardData, nCurrentCard)
    local r = {}
    -- Ч���˿�
    if not self:isValidCard(nCurrentCard) then
        return r
    end

    -- �����ж�
    if tCardData[nCurrentCard] >= 3 then
        return r
    end

    --��С���
    local nReverseCard = nCurrentCard > 10 and nCurrentCard - 10 or nCurrentCard + 10
    if tCardData[nCurrentCard] >= 1 and tCardData[nReverseCard] >= 1 and tCardData[nReverseCard] <= 2 then
        -- �����˿�
        local tTempCardData = {}
        for k, v in ipairs(tCardData) do
            tTempCardData[k] = v
        end

        --ɾ���˿�
        tTempCardData[nCurrentCard] = tTempCardData[nCurrentCard] - 1
        tTempCardData[nReverseCard] = tTempCardData[nReverseCard] - 1

        --��ȡ�ж�
        local data = {}
        data.nCenterCard = nCurrentCard
        data.nChiKind = nCurrentCard <= 10 and define.CK_XXD or define.CK_XDD
        data.tCardData =
        {
            {
                nCurrentCard,
                nCurrentCard,
                nReverseCard,
            },
        }

        while tTempCardData[nCurrentCard] > 0 do
            local tTakeOut = self:takeOutChiCard(tTempCardData,nCurrentCard)
            if tTakeOut.nType ~= define.CK_NULL then
                table.insert(data.tCardData, tTakeOut.tCardData)
            else
                break
            end
        end

        if tTempCardData[nCurrentCard] == 0 then
            table.insert(r, data)
            return r
        end
    end

    --��С���
    if tCardData[nReverseCard] == 2 and tCardData[nCurrentCard] >= 1 and tCardData[nCurrentCard] <= 2 then
        -- �����˿�
        local tTempCardData = {}
        for k, v in ipairs(tCardData) do
            tTempCardData[k] = v
        end

        --ɾ���˿�
        tTempCardData[nReverseCard] = tTempCardData[nReverseCard] - 2

        --��ȡ�ж�
        local data = {}
        data.nCenterCard = nCurrentCard
        data.nChiKind = nCurrentCard <= 10 and define.CK_XXD or define.CK_XDD
        data.tCardData =
        {
            {
                nCurrentCard,
                nReverseCard,
                nReverseCard,
            },
        }

        while tTempCardData[nCurrentCard] > 0 do
            local tTakeOut = self:takeOutChiCard(tTempCardData,nCurrentCard)
            if tTakeOut.nType ~= define.CK_NULL then
                table.insert(data.tCardData, tTakeOut.tCardData)
            else
                break
            end
        end

        if tTempCardData[nCurrentCard] == 0 then
            table.insert(r, data)
            return r
        end
    end

    -- ����ʮ��
    local nCardValue = nCurrentCard
    if nCardValue > 10 then
        nCardValue = nCurrentCard - 10
    end
    if nCardValue == 2 or nCardValue == 7 or nCardValue == 10 then
        --��������
        local tExcursion = {2,7,10}
        local nInceptIndex = 0
        if nCurrentCard > 10 then
            nInceptIndex = 10
        end

        --�����ж�
        local nExcursionIndex = 1
        for i=1, #tExcursion  do
            local nIndex = nInceptIndex + tExcursion[i]
            if nIndex ~= nCurrentCard or tCardData[nIndex] == 0 or tCardData[nIndex] == 3 then
                break
            end
            nExcursionIndex = i
        end

        -- ��ȡ�ж�
        if nExcursionIndex == #tExcursion then
            -- �����˿�
            local tTempCardData = {}
            for k, v in ipairs(tCardData) do
                tTempCardData[k] = v
            end

            --ɾ���˿�
            for j=1 , #tExcursion do
                local nIndex = nInceptIndex + tExcursion[j]
                if nIndex ~= nCurrentCard then
                    tTempCardData[nIndex] = tTempCardData[nIndex] - 1
                end
            end

            --��ȡ�ж�
            local data = {}
            data.nCenterCard = nCurrentCard
            data.nChiKind = define.CK_EQS
            data.tCardData =
            {
                {
                    nInceptIndex+tExcursion[1],
                    nInceptIndex+tExcursion[2],
                    nInceptIndex+tExcursion[3],
                },
            }

            while tTempCardData[nCurrentCard] > 0 do
                local tTakeOut = self:takeOutChiCard(tTempCardData,nCurrentCard)
                if tTakeOut.nType ~= define.CK_NULL then
                    table.insert(data.tCardData, tTakeOut.tCardData)
                else
                    break
                end
            end

            if tTempCardData[nCurrentCard] == 0 then
                table.insert(r, data)
                return r
            end
        end
    end

    --˳������
    local tExcursion = {1,2,3}
    for i=1, #tExcursion do
        local nValueIndex = nCurrentCard
        if nCurrentCard > 10 then
            nValueIndex = nCurrentCard - 10
        end

        if nValueIndex >= tExcursion[i] and nValueIndex - tExcursion[i] <= 7 then
            --��������
            local nFirstIndex = nCurrentCard - tExcursion[i]
            --�����ж�
            local nExcursionIndex = 0
            for j=1, 3 do
                local nIndex = nFirstIndex + j
                if nIndex ~= nCurrentCard and (tCardData[nIndex] == 0 or tCardData[nIndex] == 3) then
                    break
                end
                nExcursionIndex = j
            end

            --��ȡ�ж�
            if nExcursionIndex == #tExcursion then
                -- �����˿�
                local tTempCardData = {}
                for k, v in ipairs(tCardData) do
                    tTempCardData[k] = v
                end

                --ɾ���˿�
                for j=1, 3 do
                    local nIndex = nFirstIndex + j
                    if nIndex ~= nCurrentCard then
                        tTempCardData[nIndex] = tTempCardData[nIndex] - 1
                    end
                end

                local nChiKind ={define.CK_LEFT, define.CK_CENTER, define.CK_RIGHT}
                --��ȡ�ж�
                local data = {}
                data.nCenterCard = nCurrentCard
                data.nChiKind = nChiKind[i]
                data.tCardData =
                {
                    {
                        nFirstIndex+1,
                        nFirstIndex+2,
                        nFirstIndex+3,
                    },
                }

                while tTempCardData[nCurrentCard] > 0 do
                    local tTakeOut = self:takeOutChiCard(tTempCardData,nCurrentCard)
                    if tTakeOut.nType ~= define.CK_NULL then
                        table.insert(data.tCardData, tTakeOut.tCardData)
                    else
                        break
                    end
                end

                if tTempCardData[nCurrentCard] == 0 then
                    table.insert(r, data)
                    return r
                end
            end
        end
    end

    return r
end

-- ��ȡ����
function M:takeOutChiCard(tCardData, nCurrentCard)
    local r =
    {
        nType = define.CK_NULL,
        tCardData = {},
    }
    -- Ч���˿�
    if not self:isValidCard(nCurrentCard) then
        return r
    end

    -- �����ж�
    if tCardData[nCurrentCard] >= 3 then
        return r
    end

    -- ��С���
    local nReverseCard = nCurrentCard > 10 and nCurrentCard - 10 or nCurrentCard + 10
    if tCardData[nCurrentCard] >= 2 and tCardData[nReverseCard] >= 1 and tCardData[nReverseCard] <= 2 then
        -- ɾ���˿�
        tCardData[nCurrentCard] = tCardData[nCurrentCard] - 2
        tCardData[nReverseCard] = tCardData[nReverseCard] - 1

        -- ���ý��
        r.nType = nCurrentCard <= 10 and define.CK_XXD or define.CK_XDD
        r.tCardData =
        {
            nCurrentCard,
            nCurrentCard,
            nReverseCard,
        }
        return r
    end

    -- ��С���
    if tCardData[nReverseCard] == 2 and tCardData[nCurrentCard] >= 1 and tCardData[nCurrentCard] <= 2 then
        --ɾ���˿�
        tCardData[nCurrentCard] = tCardData[nCurrentCard] - 1
        tCardData[nReverseCard] = tCardData[nReverseCard] - 2

         -- ���ý��
        r.nType = nCurrentCard <= 10 and define.CK_XXD or define.CK_XDD
        r.tCardData =
        {
            nCurrentCard,
            nReverseCard,
            nReverseCard,
        }
        return r
    end

    -- ����ʮ��
    local nCardValue = nCurrentCard
    if nCardValue > 10 then
        nCardValue = nCurrentCard - 10
    end
    if nCardValue == 2 or nCardValue == 7 or nCardValue == 10 then
        --��������
        local tExcursion = {2,7,10}
        local nInceptIndex = 0
        if nCurrentCard > 10 then
            nInceptIndex = 10
        end

        --�����ж�
        local nExcursionIndex = 1
        for i=1, #tExcursion  do
            local nIndex = nInceptIndex + tExcursion[i]
            if tCardData[nIndex] == 0 or tCardData[nIndex] == 3 then
                break
            end
            nExcursionIndex = i
        end

        --�ɹ��ж�
        if nExcursionIndex == #tExcursion then
            --ɾ���˿�
            tCardData[nInceptIndex+tExcursion[1]] = tCardData[nInceptIndex+tExcursion[1]] - 1
            tCardData[nInceptIndex+tExcursion[2]] = tCardData[nInceptIndex+tExcursion[2]] - 1
            tCardData[nInceptIndex+tExcursion[3]] = tCardData[nInceptIndex+tExcursion[3]] - 1

            -- ���ý��
            r.nType = define.CK_EQS
            r.tCardData =
            {
                nInceptIndex+tExcursion[1],
                nInceptIndex+tExcursion[2],
                nInceptIndex+tExcursion[3],
            }
            return r
        end
    end

    --˳���ж�
    local tExcursion = {1,2,3}
    for i=1, #tExcursion do
        local nValueIndex = nCurrentCard
        if nCurrentCard > 10 then
            nValueIndex = nCurrentCard - 10
        end
        if nValueIndex >= tExcursion[i] and nValueIndex - tExcursion[i] <= 7 then
            --��������
            local nFirstIndex = nCurrentCard - tExcursion[i] + 1

            if not (tCardData[nFirstIndex] == 0 or tCardData[nFirstIndex] == 3 or
               tCardData[nFirstIndex+1] == 0 or tCardData[nFirstIndex+1] == 3 or
               tCardData[nFirstIndex+2] == 0 or tCardData[nFirstIndex+2] == 3) then
                --ɾ���˿�
                tCardData[nFirstIndex] = tCardData[nFirstIndex] - 1
                tCardData[nFirstIndex+1] = tCardData[nFirstIndex+1] - 1
                tCardData[nFirstIndex+2] = tCardData[nFirstIndex+2] - 1

                local nChiKind ={define.CK_LEFT, define.CK_CENTER, define.CK_RIGHT}
                -- ���ý��
                r.nType = nChiKind[i]
                r.tCardData =
                {
                    nFirstIndex,
                    nFirstIndex+1,
                    nFirstIndex+2,
                }
                return r
            end
        end
    end

    return r
end

-- �Ƿ����
function M:isChiCard(tCardData, nCurrentCard)
    local r = {}
    -- Ч���˿�
    if not self:isValidCard(nCurrentCard) then
        return false, r
    end

    -- �����˿�
    local tTempCardData = {}
    for k, v in ipairs(tCardData) do
        tTempCardData[k] = v
    end

    --�����˿�
    tTempCardData[nCurrentCard] = tTempCardData[nCurrentCard] + 1

    --��ȡ�ж�
    while tTempCardData[nCurrentCard] > 0 do
        local tTakeOut = self:takeOutChiCard(tTempCardData, nCurrentCard)
        if tTakeOut.nType == define.CK_NULL then
            break
        end
        table.insert(r, tTakeOut.tCardData)
    end

    if tTempCardData[nCurrentCard] == 0 then
        return true, r
    end

    return false, r
end

-- �Ƿ�����
function M:isTiPaoCard(tCardData, nCurrentCard)
    -- Ч���˿�
    if not self:isValidCard(nCurrentCard) then
        return false
    end

    if tCardData[nCurrentCard] == 3 then
        return true
    end

    return false
end

-- �Ƿ�����
function M:isWeiPengCard(tCardData, nCurrentCard)
    -- Ч���˿�
    if not self:isValidCard(nCurrentCard) then
        return false
    end

    --�����ж�
    if tCardData[nCurrentCard] == 2 then
        return true
    end

    return false
end

-- ��ȡ��Ϣ
function M:getWeaveHuXi(tWeave)
    local nWeaveKind = tWeave.nWeaveKind
    if nWeaveKind == define.ACK_TI then
        return tWeave.tCardData[1] > 10 and define.HUXI_TI_B or define.HUXI_TI_S
    elseif nWeaveKind == define.ACK_PAO then
        return tWeave.tCardData[1] > 10 and define.HUXI_PAO_B or define.HUXI_PAO_S
    elseif nWeaveKind == define.ACK_WEI then
        return tWeave.tCardData[1] > 10 and define.HUXI_WEI_B or define.HUXI_WEI_S
    elseif nWeaveKind == define.ACK_PENG then
        return tWeave.tCardData[1] > 10 and define.HUXI_PENG_B or define.HUXI_PENG_S
    elseif nWeaveKind == define.ACK_CHI then
        -- ��ȡ��ֵ
        local nValue1 = tWeave.tCardData[1] > 10 and tWeave.tCardData[1] - 10 or tWeave.tCardData[1]
        local nValue2 = tWeave.tCardData[2] > 10 and tWeave.tCardData[2] - 10 or tWeave.tCardData[2]
        local nValue3 = tWeave.tCardData[3] > 10 and tWeave.tCardData[3] - 10 or tWeave.tCardData[3]

        local tCardData =
        {
            [nValue1] = true,
            [nValue2] = true,
            [nValue3] = true,
        }
        -- һ������
        if tCardData[1] and tCardData[2] and tCardData[3] then
            return tWeave.tCardData[1] > 10 and define.HUXI_123_B or define.HUXI_123_S
        end

        -- ����ʮ��
        if tCardData[2] and tCardData[7] and tCardData[10] then
            return tWeave.tCardData[1] > 10 and define.HUXI_27A_B or define.HUXI_27A_S
        end

        return 0
    end

	return 0
end

return M
