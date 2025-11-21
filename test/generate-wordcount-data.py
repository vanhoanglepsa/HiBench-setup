#!/usr/bin/env python3
"""
Tạo dữ liệu test cho WordCount benchmark
"""

import random
import string

# Sample words để generate
WORDS = [
    'spark', 'hadoop', 'data', 'processing', 'big', 'analytics', 'cluster',
    'distributed', 'computing', 'mapreduce', 'yarn', 'hdfs', 'storage',
    'memory', 'disk', 'network', 'performance', 'benchmark', 'test',
    'apache', 'intel', 'hibench', 'workload', 'micro', 'machine', 'learning',
    'sql', 'query', 'join', 'aggregation', 'sort', 'shuffle', 'partition',
    'executor', 'driver', 'worker', 'master', 'node', 'container', 'resource',
    'algorithm', 'dataset', 'dataframe', 'rdd', 'transformation', 'action',
    'streaming', 'batch', 'real-time', 'latency', 'throughput', 'scalability'
]

def generate_random_text(num_lines=10000, words_per_line=15):
    """Generate random text với word frequency theo Zipfian-like distribution"""
    lines = []
    
    # Tạo weights cho Zipfian distribution (frequent words xuất hiện nhiều hơn)
    weights = [1.0/(i+1) for i in range(len(WORDS))]
    
    for _ in range(num_lines):
        # Random số từ per line
        num_words = random.randint(words_per_line - 5, words_per_line + 5)
        
        # Chọn words theo weighted distribution
        line_words = random.choices(WORDS, weights=weights, k=num_words)
        
        # Capitalize một số từ ngẫu nhiên
        line_words = [w.capitalize() if random.random() < 0.1 else w for w in line_words]
        
        lines.append(' '.join(line_words))
    
    return '\n'.join(lines)

if __name__ == "__main__":
    import sys
    
    num_lines = int(sys.argv[1]) if len(sys.argv) > 1 else 10000
    
    print(f"Generating {num_lines} lines...")
    text = generate_random_text(num_lines)
    
    # Write to stdout
    print(text)

