# coding: utf-8

require 'fileutils'
require 'pp'

# format index 
# 配列から飛び出したときの対処
def f_i_with_array(i, array)
  if i < 0  
    return 0 
  elsif i >= array.size
    return array.size - 1
  end
  i
end

# 前のnスライドを取得
# 自分自身は出さない
def before_list(array, index, slide_size)
  a = array[f_i_with_array((index-slide_size), array)..index]
  if a.nil? or a.size == 0 
    return []
  end
  a.pop
  a
end

def after_list(array, index, slide_size)
  a = array[index..f_i_with_array((index+slide_size), array)]
  if a.nil? or a.size == 0 
    return []
  end
  a.shift 
  a
end

#
# afterとbeforeのlistのフォーマット
# input [["s1",3],["s1",2],["s2",1]], [], 3
# return [[["s1", 3], ["s1", 2], ["s2", 1]], [["", 1], ["", 2], ["", 3]]]
#
# [test]
# reuturn [3,2,1], [1,2,3] 
# pp before_after_format([["s1",3],["s1",2],["s2",1]], [], 3)
def before_after_format(before_list, after_list, slide_num)
  at = after_list 
  if after_list.size != slide_num
    # pathを空文字にする(後の混同をなくすため)
    at = before_list.reverse.map {|x| ["", x[1]]}
    for ai in 0..(after_list.size-1)
      at[ai] = after_list[ai]
    end
  end

  bt = before_list 
  if before_list.size != slide_num
    # pathを空文字にする(後の混同をなくすため)
    bt = after_list.map {|x| ["", x[1]]}
    for bi in 0..(before_list.size-1)
      bt[bi] = before_list.reverse[bi]
    end
    bt = bt.reverse
  end

  return [bt, at]
end

# smoothの場合の重み計算
def smooth_devide(slide_num)
  if slide_num <= 1
    return 1
  end

  sum = 0.0
  (2..slide_num).to_a.each do |i|
    sum += 1.0/i
  end
  return sum*2 + 1
end

# listにsmoothをかける
# @param: i index番号
def smooth_weight(path_sim_arr_list, i, slide_num)
  # 前後スライド取得
  _before_list = before_list(path_sim_arr_list, i, slide_num)
  _after_list = after_list(path_sim_arr_list, i, slide_num)

  # 講演の端っこスライドの処理
  # 逆側の情報をコピー
  _before_list, _after_list = before_after_format(_before_list, _after_list, slide_num)

  # 重みの計算 (after)
  after_sum = 0.0
  _after_list.each_with_index do |(path, sim), j|
    after_sum += sim.to_f/(i+2)
  end

  # 重みの計算 (before)
  before_sum = 0.0
  _before_list.reverse.each_with_index do |(path, sim), j|
    before_sum += sim.to_f/(i+2)
  end

  path = path_sim_arr_list[i][0]
  score = after_sum + before_sum + path_sim_arr_list[i][1].to_f

  # 全体の重みでわる
  # score = score/smooth_devide(slide_num)

  [path, score]
end

# listにsmoothをかける
# @param: i index番号
def average_weight(path_sim_arr_list, i, slide_num)
  # 前後スライド取得
  _before_list = before_list(path_sim_arr_list, i, slide_num)
  _after_list = after_list(path_sim_arr_list, i, slide_num)

  # 講演の端っこスライドの処理
  # 逆側の情報をコピー
  _before_list, _after_list = before_after_format(_before_list, _after_list, slide_num)

  # 重みの計算 (after)
  after_sum = 0.0
  _after_list.each_with_index do |(path, sim), j|
    after_sum += sim.to_f
  end

  # 重みの計算 (before)
  before_sum = 0.0
  _before_list.reverse.each_with_index do |(path, sim), j|
    before_sum += sim.to_f
  end

  path = path_sim_arr_list[i][0]
  score = ( after_sum + before_sum + path_sim_arr_list[i][1].to_f ) / (slide_num * 2 + 1)

  [path, score]
end

def gaussian(x, mean, sigma)
  gauss = (1/Math::sqrt(2.0*Math::PI*sigma**2)) * Math::exp(-(x-mean)**2/(2*sigma**2))
  gauss
end

# listにsmoothをかける
# @param: i index番号
def gauss_weight(path_sim_arr_list, i, slide_num, sigma)
  # 前後スライド取得
  _before_list = before_list(path_sim_arr_list, i, slide_num)
  _after_list = after_list(path_sim_arr_list, i, slide_num)

  # 講演の端っこスライドの処理
  # 逆側の情報をコピー
  _before_list, _after_list = before_after_format(_before_list, _after_list, slide_num)

  # ガウスの正規化用
  gauss_norm = 0.0
  for j in -slide_num..slide_num
    gauss_norm += gaussian(j, 0, sigma)
  end

  # 重みの計算 (after)
  after_sum = 0.0
  _after_list.each_with_index do |(path, sim), j|
    after_sum += sim.to_f * gaussian(j+1, 0, sigma)/gauss_norm
  end

  # 重みの計算 (before)
  before_sum = 0.0
  _before_list.reverse.each_with_index do |(path, sim), j|
    before_sum += sim.to_f  * gaussian(j+1, 0, sigma)/gauss_norm
  end

  path = path_sim_arr_list[i][0]
  score = after_sum + before_sum + ( path_sim_arr_list[i][1].to_f * gaussian(0, 0, sigma)/gauss_norm )

  [path, score]
end


# 入力と出力のヘルパー
# 配列の配列を出力
def in_out(indir, outdir) 
  Dir.glob("#{indir}/*").each do |file|
    # sfを返す
    array_list = yield SimFile.new(file)

    # sortして、上位1000個を出す
    array_list = sort_with_score(array_list)[0..(1000-1)]

    s = ""
    array_list.each do |array|
      s += array.join(' ') + "\n"
    end

    if /\/(\d+.txt)$/ =~ file
      File.write("#{outdir}/#{$1}", s) 
    end
  end
end

def dd(ele)
  pp ele
  abort
end

def sort_with_score(shohin)
  sorted = shohin.sort do |a, b|
    # 降順
    -(a[1] <=> b[1])
  end
  sorted
end

class SimFile
  attr_reader :path

  def initialize(path)
    @path = path
    @list = nil
  end

  def lectures
    list = path_sim_arr_list
    res = []
    list.each do |path, sim|
      if /(\d+-\d+)_\d+\.txt/ =~ path
        res << $1
      end
    end
    res.uniq
  end

  def path_sim_arr_list
    if (!@list.nil?)
      return @list
    end

    path_sim_arr_list = []
    File.foreach(@path) do |line|
      path_sim_arr_list << line.split(' ') 
    end

    @list = sort_with_path(path_sim_arr_list)
    @list
  end

  # ある講演のデータを取得
  def path_sim_arr_list_with_lecture(lecture_id)
    path_sim_arr_list.select {|x| x[0].match(/#{lecture_id}/)}
  end

  private 
  def sort_with_path(shohin)
    sorted = shohin.sort do |a, b|
      a[0] <=> b[0] 
    end
    sorted
  end
end

# s = 0.0
# for i in -3..3
#   s += gaussian(i, 0, 1.3)
# end
#
# for i in -3..3
#   pp gaussian(i, 0, 1.3) / s
# end
# dd("")

# main
indir = "./input_dir"
outdir = "./output_dir"
slide_num = 7
# per = 0.20

in_out(indir, outdir) do |sf|
  res = []

  sf.lectures.each do |lecture|
    list = []
    path_sim_arr_list = sf.path_sim_arr_list_with_lecture(lecture)

    # スライドのpercent指定
    # slide_num = (path_sim_arr_list.size.to_f * per / 2 - 1).round

    for i in 0..(path_sim_arr_list.size-1)
      list <<  gauss_weight(path_sim_arr_list, i, slide_num, 2.5)
      # list <<  smooth_weight(path_sim_arr_list, i, slide_num)
      # list <<  average_weight(path_sim_arr_list, i, slide_num)
    end

    res += list

  end


  pp "[ok] #{sf.path}" 

  # return [[1,1],[1,1],...]
  res
end
