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

class SimFile
  def initialize(path)
    @path = path
    @list = nil
  end

  def path_sim_arr_list
    if (!@list.nil?)
      return @list
    end

    path_sim_arr_list = []
    File.foreach(@path) do |line|
      path_sim_arr_list << line.split(' ') 
    end

    @list = path_sim_arr_list
    @list
  end
end


# main
DIR_PATH = "./bm25/result"

file = "#{DIR_PATH}/01.txt"
sf = SimFile.new(file)

i = 1 
slide_num = 3

_before_list = before_list(sf.path_sim_arr_list, i, slide_num)
_affter_list = after_list(sf.path_sim_arr_list, i, slide_num)

# 重みの計算
affter_sum = 0.0
_affter_list.each_with_index do |(path, sim), i|
  affter_sum += sim.to_f/(i+2)
end

before_sum = 0.0
_before_list.reverse.each_with_index do |(path, sim), i|
  before_sum += sim.to_f/(i+2)
end

pp (affter_sum + before_sum + sf.path_sim_arr_list[i][1].to_f) / (_before_list.size + _affter_list.size + 1)

abort

cnt = 0
dirs = Dir.glob('./slide_for_word2vec/*')
dirs.each do |dir|
        p "#{cnt} #{dir} "
        extract_size = 20
        files = Dir.glob("#{dir}/*")
        files.shuffle!
        files = files[0..(extract_size-1)] if files.size > extract_size
        files.each_with_index do |file, i|
                FileUtils.cp file, "#{TMP_PATH}/#{cnt}.txt"
                cnt += 1
        end
end
