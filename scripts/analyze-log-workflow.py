#!/usr/bin/env python3
"""
Advanced HiBench Log Analyzer
Provides deep analysis, classification, statistics, and professional reporting
"""

import re
import sys
import json
import statistics
from pathlib import Path
from collections import defaultdict, OrderedDict
from datetime import datetime
from typing import Dict, List, Set, Optional, Tuple
from dataclasses import dataclass, field


@dataclass
class LogEntry:
    """Represents a single log entry with classification"""
    line_number: int
    content: str
    level: str = "INFO"  # INFO, WARN, ERROR, DEBUG
    category: str = "UNKNOWN"  # SPARK, HDFS, HIBENCH, SYSTEM, MAPREDUCE
    timestamp: Optional[str] = None
    event_type: Optional[str] = None
    metrics: Dict = field(default_factory=dict)


@dataclass
class PerformanceMetrics:
    """Performance metrics extracted from logs"""
    total_duration: float = 0.0
    prepare_duration: float = 0.0
    run_duration: float = 0.0
    report_duration: float = 0.0
    job_duration: float = 0.0
    stage_durations: List[float] = field(default_factory=list)
    task_durations: List[float] = field(default_factory=list)
    throughput: float = 0.0
    data_size: int = 0
    records_processed: int = 0


@dataclass
class Statistics:
    """Statistical analysis of metrics"""
    mean: float = 0.0
    median: float = 0.0
    std_dev: float = 0.0
    min: float = 0.0
    max: float = 0.0
    p50: float = 0.0
    p75: float = 0.0
    p95: float = 0.0
    p99: float = 0.0
    count: int = 0


class AdvancedLogAnalyzer:
    """Advanced log analyzer with deep analysis capabilities"""
    
    def __init__(self):
        # Log level patterns
        self.level_patterns = {
            'ERROR': r'ERROR|❌|Exception|Failed|FAILED|Error',
            'WARN': r'WARN|WARNING|⚠️',
            'INFO': r'INFO',
            'DEBUG': r'DEBUG'
        }
        
        # Category patterns
        self.category_patterns = {
            'SPARK': r'SparkContext|DAGScheduler|Executor|TaskSetManager|SparkSubmit|SparkSession',
            'HDFS': r'hdfs|HDFS|NameNode|DataNode|FileSystem',
            'HIBENCH': r'HiBench|hibench|benchmark|Benchmark',
            'MAPREDUCE': r'MapReduce|Map-Reduce|JobClient|mapred|Job \d+',
            'SYSTEM': r'System|JVM|GC|Memory|CPU|Thread'
        }
        
        # Event patterns
        self.event_patterns = {
            # Spark events
            'spark_context_start': r'SparkContext.*Running Spark version|SparkContext.*Submitted application',
            'spark_context_stop': r'SparkContext.*Successfully stopped',
            'job_start': r'Starting job|Job \d+ started|Running job',
            'job_finish': r'Job \d+ finished|Job.*completed|Job.*took',
            'stage_submit': r'Submitting.*Stage (\d+)',
            'stage_finish': r'Stage (\d+).*finished in ([\d.]+) s',
            'task_start': r'Starting task (\d+\.\d+)',
            'task_finish': r'Finished task (\d+\.\d+).*in ([\d]+) ms',
            'executor_added': r'Executor added|Granted executor|Registered executor',
            'executor_removed': r'Executor removed|Lost executor',
            'shuffle_read': r'Shuffle read|Shuffle.*read',
            'shuffle_write': r'Shuffle write|Shuffle.*write',
            
            # HDFS events
            'hdfs_read': r'hdfs.*-cat|hdfs.*-get|Reading from',
            'hdfs_write': r'hdfs.*-put|hdfs.*-copyFromLocal|Writing to',
            'hdfs_delete': r'hdfs.*-rm|Deleted hdfs',
            'hdfs_mkdir': r'hdfs.*-mkdir|Created directory',
            
            # Performance metrics
            'duration': r'Duration[:\s]+([\d.]+)\s*(s|ms|seconds)',
            'throughput': r'Throughput[:\s]+([\d.]+)',
            'data_size': r'(\d+)\s*(bytes|KB|MB|GB|TB)',
            'records': r'(\d+)\s*(records|rows)',
            
            # Phases
            'prepare_phase': r'1️⃣\s+PREPARE PHASE|PREPARE PHASE|prepare phase',
            'run_phase': r'2️⃣\s+RUN PHASE|RUN PHASE|run phase',
            'report_phase': r'3️⃣\s+REPORT|REPORT PHASE|report phase'
        }
        
        # Metric extraction patterns
        self.metric_patterns = {
            'bytes_read': r'Bytes Read[:\s]+(\d+)',
            'bytes_written': r'Bytes Written[:\s]+(\d+)',
            'records_read': r'Map input records[:\s]+(\d+)|Input records[:\s]+(\d+)',
            'records_written': r'Map output records[:\s]+(\d+)|Output records[:\s]+(\d+)',
            'gc_time': r'GC time elapsed[:\s]+(\d+)\s*ms',
            'heap_usage': r'Total committed heap usage[:\s]+(\d+)\s*bytes',
            'tasks_total': r'Total tasks[:\s]+(\d+)',
            'tasks_completed': r'Completed tasks[:\s]+(\d+)',
            'tasks_failed': r'Failed tasks[:\s]+(\d+)'
        }
    
    def classify_log_entry(self, line: str, line_num: int) -> LogEntry:
        """Classify a log entry by level, category, and extract metadata"""
        entry = LogEntry(line_number=line_num, content=line.strip())
        
        # Detect log level
        for level, pattern in self.level_patterns.items():
            if re.search(pattern, line, re.IGNORECASE):
                entry.level = level
                break
        
        # Detect category
        for category, pattern in self.category_patterns.items():
            if re.search(pattern, line, re.IGNORECASE):
                entry.category = category
                break
        
        # Extract timestamp
        timestamp_match = re.search(r'(\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})', line)
        if timestamp_match:
            entry.timestamp = timestamp_match.group(1)
        
        # Detect event type
        for event_type, pattern in self.event_patterns.items():
            if re.search(pattern, line, re.IGNORECASE):
                entry.event_type = event_type
                break
        
        # Extract metrics
        for metric_name, pattern in self.metric_patterns.items():
            match = re.search(pattern, line, re.IGNORECASE)
            if match:
                try:
                    value = int(match.group(1))
                    entry.metrics[metric_name] = value
                except (ValueError, IndexError):
                    pass
        
        return entry
    
    def parse_log_file(self, log_path: Path) -> Dict:
        """Parse log file with advanced analysis"""
        if not log_path.exists():
            return None
        
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        # Classify all log entries
        log_entries = [self.classify_log_entry(line, i+1) for i, line in enumerate(lines)]
        
        # Extract structured data
        analysis = {
            'file': str(log_path.name),
            'benchmark': self._extract_benchmark_name(log_path.name),
            'timestamp': self._extract_timestamp(log_path.name),
            'total_lines': len(lines),
            'log_entries': log_entries,
            
            # Classifications
            'log_levels': self._classify_by_level(log_entries),
            'log_categories': self._classify_by_category(log_entries),
            'events': self._extract_events(log_entries),
            
            # Phases
            'phases': self._extract_phases_detailed(log_entries),
            
            # Spark analysis
            'spark_analysis': self._analyze_spark(log_entries),
            
            # HDFS analysis
            'hdfs_analysis': self._analyze_hdfs(log_entries),
            
            # Performance metrics
            'performance': self._extract_performance_metrics(log_entries),
            
            # Errors and warnings
            'errors': self._extract_errors_detailed(log_entries),
            'warnings': self._extract_warnings_detailed(log_entries),
            
            # Statistics
            'statistics': self._calculate_statistics(log_entries),
            
            # Bottlenecks
            'bottlenecks': self._identify_bottlenecks(log_entries),
            
            # Anomalies
            'anomalies': self._detect_anomalies(log_entries)
        }
        
        return analysis
    
    def _extract_benchmark_name(self, filename: str) -> str:
        """Extract benchmark name from filename"""
        match = re.search(r'benchmark-([^-]+)-([^-]+)-([^-]+)', filename)
        if match:
            return f"{match.group(1)}/{match.group(2)}"
        return "unknown"
    
    def _extract_timestamp(self, filename: str) -> Optional[str]:
        """Extract timestamp from filename"""
        match = re.search(r'(\d{8}_\d{6})', filename)
        return match.group(1) if match else None
    
    def _classify_by_level(self, entries: List[LogEntry]) -> Dict:
        """Classify entries by log level"""
        classification = defaultdict(list)
        for entry in entries:
            classification[entry.level].append(entry)
        return {
            level: {
                'count': len(entries_list),
                'percentage': (len(entries_list) / len(entries) * 100) if entries else 0,
                'entries': entries_list[:10]  # Sample
            }
            for level, entries_list in classification.items()
        }
    
    def _classify_by_category(self, entries: List[LogEntry]) -> Dict:
        """Classify entries by category"""
        classification = defaultdict(list)
        for entry in entries:
            classification[entry.category].append(entry)
        return {
            category: {
                'count': len(entries_list),
                'percentage': (len(entries_list) / len(entries) * 100) if entries else 0
            }
            for category, entries_list in classification.items()
        }
    
    def _extract_events(self, entries: List[LogEntry]) -> Dict:
        """Extract and categorize events"""
        events = defaultdict(list)
        for entry in entries:
            if entry.event_type:
                events[entry.event_type].append({
                    'line': entry.line_number,
                    'timestamp': entry.timestamp,
                    'content': entry.content[:200]  # Truncate
                })
        return dict(events)
    
    def _extract_phases_detailed(self, entries: List[LogEntry]) -> Dict:
        """Extract detailed phase information"""
        phases = {}
        
        prepare_entries = [e for e in entries if e.event_type == 'prepare_phase']
        run_entries = [e for e in entries if e.event_type == 'run_phase']
        report_entries = [e for e in entries if e.event_type == 'report_phase']
        
        if prepare_entries:
            phases['prepare'] = {
                'start_line': min(e.line_number for e in prepare_entries),
                'end_line': max(e.line_number for e in prepare_entries),
                'entries_count': len(prepare_entries)
            }
        
        if run_entries:
            phases['run'] = {
                'start_line': min(e.line_number for e in run_entries),
                'end_line': max(e.line_number for e in run_entries),
                'entries_count': len(run_entries)
            }
        
        if report_entries:
            phases['report'] = {
                'start_line': min(e.line_number for e in report_entries),
                'end_line': max(e.line_number for e in report_entries),
                'entries_count': len(report_entries)
            }
        
        return phases
    
    def _analyze_spark(self, entries: List[LogEntry]) -> Dict:
        """Deep analysis of Spark events"""
        spark_entries = [e for e in entries if e.category == 'SPARK']
        
        # Extract stages
        stages = {}
        for entry in spark_entries:
            stage_match = re.search(r'Stage (\d+)', entry.content)
            if stage_match:
                stage_id = stage_match.group(1)
                if stage_id not in stages:
                    stages[stage_id] = {
                        'id': stage_id,
                        'events': [],
                        'duration': None
                    }
                stages[stage_id]['events'].append({
                    'line': entry.line_number,
                    'type': entry.event_type,
                    'timestamp': entry.timestamp
                })
                
                # Extract duration
                duration_match = re.search(r'finished in ([\d.]+) s', entry.content)
                if duration_match:
                    stages[stage_id]['duration'] = float(duration_match.group(1))
        
        # Extract tasks
        tasks = []
        for entry in spark_entries:
            task_match = re.search(r'task (\d+\.\d+)', entry.content, re.IGNORECASE)
            if task_match:
                task_id = task_match.group(1)
                duration_match = re.search(r'in ([\d]+) ms', entry.content)
                duration = int(duration_match.group(1)) if duration_match else None
                tasks.append({
                    'id': task_id,
                    'line': entry.line_number,
                    'duration_ms': duration
                })
        
        # Extract jobs
        jobs = []
        for entry in spark_entries:
            if entry.event_type in ['job_start', 'job_finish']:
                job_match = re.search(r'Job (\d+)', entry.content)
                if job_match:
                    job_id = job_match.group(1)
                    jobs.append({
                        'id': job_id,
                        'type': entry.event_type,
                        'line': entry.line_number,
                        'timestamp': entry.timestamp
                    })
        
        return {
            'total_entries': len(spark_entries),
            'stages': stages,
            'tasks': tasks,
            'jobs': jobs,
            'stage_count': len(stages),
            'task_count': len(tasks),
            'job_count': len(jobs)
        }
    
    def _analyze_hdfs(self, entries: List[LogEntry]) -> Dict:
        """Deep analysis of HDFS operations"""
        hdfs_entries = [e for e in entries if e.category == 'HDFS']
        
        operations = defaultdict(int)
        for entry in hdfs_entries:
            if entry.event_type:
                operations[entry.event_type] += 1
        
        # Extract data sizes
        data_sizes = []
        for entry in hdfs_entries:
            size_match = re.search(r'(\d+)\s*(bytes|KB|MB|GB)', entry.content, re.IGNORECASE)
            if size_match:
                value = int(size_match.group(1))
                unit = size_match.group(2).upper()
                # Convert to bytes
                multipliers = {'KB': 1024, 'MB': 1024**2, 'GB': 1024**3, 'TB': 1024**4}
                bytes_value = value * multipliers.get(unit, 1)
                data_sizes.append(bytes_value)
        
        return {
            'total_entries': len(hdfs_entries),
            'operations': dict(operations),
            'data_sizes': data_sizes,
            'total_data_bytes': sum(data_sizes) if data_sizes else 0
        }
    
    def _extract_performance_metrics(self, entries: List[LogEntry]) -> PerformanceMetrics:
        """Extract comprehensive performance metrics"""
        metrics = PerformanceMetrics()
        
        # Extract durations
        for entry in entries:
            # Total duration
            duration_match = re.search(r'Total Duration[:\s]+(\d+)s?', entry.content, re.IGNORECASE)
            if duration_match:
                metrics.total_duration = float(duration_match.group(1))
            
            # Job duration
            job_duration_match = re.search(r'Job.*took ([\d.]+) s', entry.content, re.IGNORECASE)
            if job_duration_match:
                metrics.job_duration = float(job_duration_match.group(1))
            
            # Stage durations
            stage_duration_match = re.search(r'Stage \d+.*finished in ([\d.]+) s', entry.content)
            if stage_duration_match:
                metrics.stage_durations.append(float(stage_duration_match.group(1)))
            
            # Task durations
            task_duration_match = re.search(r'Finished task.*in ([\d]+) ms', entry.content)
            if task_duration_match:
                metrics.task_durations.append(int(task_duration_match.group(1)))
        
        # Extract data metrics
        for entry in entries:
            # Records
            records_match = re.search(r'(\d+)\s*(records|rows)', entry.content, re.IGNORECASE)
            if records_match:
                metrics.records_processed = max(metrics.records_processed, int(records_match.group(1)))
            
            # Data size
            size_match = re.search(r'(\d+)\s*(bytes|KB|MB|GB)', entry.content, re.IGNORECASE)
            if size_match:
                value = int(size_match.group(1))
                unit = size_match.group(2).upper()
                multipliers = {'KB': 1024, 'MB': 1024**2, 'GB': 1024**3}
                bytes_value = value * multipliers.get(unit, 1)
                metrics.data_size = max(metrics.data_size, bytes_value)
        
        # Calculate throughput
        if metrics.total_duration > 0 and metrics.data_size > 0:
            metrics.throughput = metrics.data_size / metrics.total_duration  # bytes per second
        
        return metrics
    
    def _extract_errors_detailed(self, entries: List[LogEntry]) -> List[Dict]:
        """Extract detailed error information"""
        errors = []
        for entry in entries:
            if entry.level == 'ERROR':
                error_info = {
                    'line': entry.line_number,
                    'category': entry.category,
                    'content': entry.content,
                    'timestamp': entry.timestamp
                }
                
                # Extract error type
                if 'Exception' in entry.content:
                    exception_match = re.search(r'([A-Za-z0-9_\.]+Exception)', entry.content)
                    if exception_match:
                        error_info['exception_type'] = exception_match.group(1)
                
                errors.append(error_info)
        return errors
    
    def _extract_warnings_detailed(self, entries: List[LogEntry]) -> List[Dict]:
        """Extract detailed warning information"""
        warnings = []
        for entry in entries:
            if entry.level == 'WARN':
                warnings.append({
                    'line': entry.line_number,
                    'category': entry.category,
                    'content': entry.content[:200],
                    'timestamp': entry.timestamp
                })
        return warnings
    
    def _calculate_statistics(self, entries: List[LogEntry]) -> Dict:
        """Calculate comprehensive statistics"""
        stats = {}
        
        # Task duration statistics
        task_durations = []
        for entry in entries:
            duration_match = re.search(r'Finished task.*in ([\d]+) ms', entry.content)
            if duration_match:
                task_durations.append(int(duration_match.group(1)))
        
        if task_durations:
            stats['task_durations'] = self._calculate_percentiles(task_durations)
        
        # Stage duration statistics
        stage_durations = []
        for entry in entries:
            duration_match = re.search(r'Stage \d+.*finished in ([\d.]+) s', entry.content)
            if duration_match:
                stage_durations.append(float(duration_match.group(1)))
        
        if stage_durations:
            stats['stage_durations'] = self._calculate_percentiles(stage_durations)
        
        return stats
    
    def _calculate_percentiles(self, values: List[float]) -> Statistics:
        """Calculate percentiles and statistics"""
        if not values:
            return Statistics()
        
        sorted_values = sorted(values)
        n = len(sorted_values)
        
        def percentile(p):
            k = (n - 1) * p
            f = int(k)
            c = k - f
            if f + 1 < n:
                return sorted_values[f] * (1 - c) + sorted_values[f + 1] * c
            return sorted_values[f]
        
        return Statistics(
            mean=statistics.mean(values),
            median=statistics.median(values),
            std_dev=statistics.stdev(values) if n > 1 else 0.0,
            min=min(values),
            max=max(values),
            p50=percentile(0.50),
            p75=percentile(0.75),
            p95=percentile(0.95),
            p99=percentile(0.99),
            count=n
        )
    
    def _identify_bottlenecks(self, entries: List[LogEntry]) -> List[Dict]:
        """Identify performance bottlenecks"""
        bottlenecks = []
        
        # Find long-running stages
        for entry in entries:
            stage_duration_match = re.search(r'Stage (\d+).*finished in ([\d.]+) s', entry.content)
            if stage_duration_match:
                stage_id = stage_duration_match.group(1)
                duration = float(stage_duration_match.group(2))
                if duration > 10.0:  # Threshold: 10 seconds
                    bottlenecks.append({
                        'type': 'slow_stage',
                        'stage_id': stage_id,
                        'duration': duration,
                        'line': entry.line_number
                    })
        
        # Find slow tasks
        for entry in entries:
            task_duration_match = re.search(r'Finished task.*in ([\d]+) ms', entry.content)
            if task_duration_match:
                duration = int(task_duration_match.group(1))
                if duration > 5000:  # Threshold: 5 seconds
                    bottlenecks.append({
                        'type': 'slow_task',
                        'duration_ms': duration,
                        'line': entry.line_number
                    })
        
        # Find GC issues
        for entry in entries:
            gc_match = re.search(r'GC time elapsed[:\s]+(\d+)\s*ms', entry.content)
            if gc_match:
                gc_time = int(gc_match.group(1))
                if gc_time > 1000:  # Threshold: 1 second
                    bottlenecks.append({
                        'type': 'high_gc_time',
                        'gc_time_ms': gc_time,
                        'line': entry.line_number
                    })
        
        return bottlenecks
    
    def _detect_anomalies(self, entries: List[LogEntry]) -> List[Dict]:
        """Detect anomalies in logs"""
        anomalies = []
        
        # Detect error spikes
        error_count = sum(1 for e in entries if e.level == 'ERROR')
        if error_count > len(entries) * 0.05:  # More than 5% errors
            anomalies.append({
                'type': 'high_error_rate',
                'error_count': error_count,
                'error_percentage': (error_count / len(entries) * 100) if entries else 0
            })
        
        # Detect missing phases
        has_prepare = any(e.event_type == 'prepare_phase' for e in entries)
        has_run = any(e.event_type == 'run_phase' for e in entries)
        if not has_prepare or not has_run:
            anomalies.append({
                'type': 'missing_phases',
                'has_prepare': has_prepare,
                'has_run': has_run
            })
        
        # Detect failed tasks
        for entry in entries:
            if 'Failed task' in entry.content or 'Task failed' in entry.content:
                anomalies.append({
                    'type': 'failed_task',
                    'line': entry.line_number,
                    'content': entry.content[:200]
                })
        
        return anomalies
    
    def generate_comprehensive_report(self, analyses: List[Dict]) -> str:
        """Generate comprehensive analysis report"""
        report = []
        
        report.append("=" * 100)
        report.append(" " * 30 + "HIBENCH ADVANCED LOG ANALYSIS REPORT")
        report.append("=" * 100)
        report.append("")
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Analyzed Files: {len(analyses)}")
        report.append("")
        
        # Executive Summary
        report.append("=" * 100)
        report.append("EXECUTIVE SUMMARY")
        report.append("=" * 100)
        report.append("")
        
        for analysis in analyses:
            report.append(f"📊 Benchmark: {analysis['benchmark']}")
            report.append(f"   File: {analysis['file']}")
            report.append(f"   Total Lines: {analysis['total_lines']}")
            report.append(f"   Status: {'✅ SUCCESS' if not analysis['errors'] else '❌ ERRORS DETECTED'}")
            if analysis['performance'].total_duration > 0:
                report.append(f"   Total Duration: {analysis['performance'].total_duration:.2f}s")
            report.append("")
        
        # Detailed Analysis for each file
        for idx, analysis in enumerate(analyses, 1):
            report.append("=" * 100)
            report.append(f"DETAILED ANALYSIS #{idx}: {analysis['benchmark']}")
            report.append("=" * 100)
            report.append("")
            
            # Log Classification
            report.append("📋 LOG CLASSIFICATION")
            report.append("-" * 100)
            report.append("")
            report.append("Log Levels:")
            for level, data in analysis['log_levels'].items():
                report.append(f"   {level:8s}: {data['count']:6d} entries ({data['percentage']:5.2f}%)")
            report.append("")
            report.append("Log Categories:")
            for category, data in analysis['log_categories'].items():
                report.append(f"   {category:12s}: {data['count']:6d} entries ({data['percentage']:5.2f}%)")
            report.append("")
            
            # Performance Metrics
            report.append("⚡ PERFORMANCE METRICS")
            report.append("-" * 100)
            perf = analysis['performance']
            if perf.total_duration > 0:
                report.append(f"   Total Duration: {perf.total_duration:.2f}s")
            if perf.job_duration > 0:
                report.append(f"   Job Duration: {perf.job_duration:.2f}s")
            if perf.stage_durations:
                report.append(f"   Stages: {len(perf.stage_durations)}")
                report.append(f"   Avg Stage Duration: {statistics.mean(perf.stage_durations):.2f}s")
            if perf.task_durations:
                report.append(f"   Tasks: {len(perf.task_durations)}")
                avg_task = statistics.mean(perf.task_durations)
                report.append(f"   Avg Task Duration: {avg_task:.2f}ms")
            if perf.data_size > 0:
                report.append(f"   Data Size: {self._format_bytes(perf.data_size)}")
            if perf.throughput > 0:
                report.append(f"   Throughput: {self._format_bytes(perf.throughput)}/s")
            report.append("")
            
            # Statistics
            if analysis['statistics']:
                report.append("📈 STATISTICAL ANALYSIS")
                report.append("-" * 100)
                if 'task_durations' in analysis['statistics']:
                    stats = analysis['statistics']['task_durations']
                    report.append("Task Duration Statistics:")
                    report.append(f"   Mean: {stats.mean:.2f}ms")
                    report.append(f"   Median (p50): {stats.median:.2f}ms")
                    report.append(f"   p75: {stats.p75:.2f}ms")
                    report.append(f"   p95: {stats.p95:.2f}ms")
                    report.append(f"   p99: {stats.p99:.2f}ms")
                    report.append(f"   Std Dev: {stats.std_dev:.2f}ms")
                    report.append(f"   Min: {stats.min:.2f}ms, Max: {stats.max:.2f}ms")
                    report.append("")
            
            # Spark Analysis
            spark = analysis['spark_analysis']
            if spark['stage_count'] > 0:
                report.append("🔥 SPARK ANALYSIS")
                report.append("-" * 100)
                report.append(f"   Stages: {spark['stage_count']}")
                report.append(f"   Tasks: {spark['task_count']}")
                report.append(f"   Jobs: {spark['job_count']}")
                if spark['stages']:
                    report.append("   Stage Durations:")
                    for stage_id, stage_data in list(spark['stages'].items())[:5]:
                        if stage_data.get('duration'):
                            report.append(f"      Stage {stage_id}: {stage_data['duration']:.2f}s")
                report.append("")
            
            # HDFS Analysis
            hdfs = analysis['hdfs_analysis']
            if hdfs['total_entries'] > 0:
                report.append("💾 HDFS ANALYSIS")
                report.append("-" * 100)
                report.append(f"   Total Operations: {hdfs['total_entries']}")
                report.append("   Operations Breakdown:")
                for op, count in hdfs['operations'].items():
                    report.append(f"      {op}: {count}")
                if hdfs['total_data_bytes'] > 0:
                    report.append(f"   Total Data: {self._format_bytes(hdfs['total_data_bytes'])}")
                report.append("")
            
            # Errors and Warnings
            if analysis['errors']:
                report.append("❌ ERRORS")
                report.append("-" * 100)
                report.append(f"   Total Errors: {len(analysis['errors'])}")
                for error in analysis['errors'][:5]:  # Show first 5
                    report.append(f"   Line {error['line']}: {error['content'][:80]}")
                report.append("")
            
            if analysis['warnings']:
                report.append("⚠️  WARNINGS")
                report.append("-" * 100)
                report.append(f"   Total Warnings: {len(analysis['warnings'])}")
                for warning in analysis['warnings'][:5]:  # Show first 5
                    report.append(f"   Line {warning['line']}: {warning['content'][:80]}")
                report.append("")
            
            # Bottlenecks
            if analysis['bottlenecks']:
                report.append("🐌 BOTTLENECKS DETECTED")
                report.append("-" * 100)
                for bottleneck in analysis['bottlenecks'][:10]:
                    report.append(f"   {bottleneck['type']}: Line {bottleneck['line']}")
                    if 'duration' in bottleneck:
                        report.append(f"      Duration: {bottleneck['duration']:.2f}s")
                report.append("")
            
            # Anomalies
            if analysis['anomalies']:
                report.append("🔍 ANOMALIES DETECTED")
                report.append("-" * 100)
                for anomaly in analysis['anomalies']:
                    report.append(f"   {anomaly['type']}: {anomaly}")
                report.append("")
            
            report.append("")
        
        # Comparative Analysis
        if len(analyses) > 1:
            report.append("=" * 100)
            report.append("COMPARATIVE ANALYSIS")
            report.append("=" * 100)
            report.append("")
            
            # Compare durations
            durations = [a['performance'].total_duration for a in analyses if a['performance'].total_duration > 0]
            if durations:
                report.append("Duration Comparison:")
                report.append(f"   Fastest: {min(durations):.2f}s")
                report.append(f"   Slowest: {max(durations):.2f}s")
                report.append(f"   Average: {statistics.mean(durations):.2f}s")
                report.append("")
        
        report.append("=" * 100)
        report.append("END OF REPORT")
        report.append("=" * 100)
        
        return "\n".join(report)
    
    def _format_bytes(self, bytes_value: float) -> str:
        """Format bytes to human-readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.2f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.2f} PB"


def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: analyze-log-workflow.py <log_file1> [log_file2] ...")
        print("   or: analyze-log-workflow.py --dir <logs_directory>")
        sys.exit(1)
    
    analyzer = AdvancedLogAnalyzer()
    analyses = []
    
    # Parse arguments
    if sys.argv[1] == '--dir':
        if len(sys.argv) < 3:
            print("Error: Please specify logs directory")
            sys.exit(1)
        logs_dir = Path(sys.argv[2])
        log_files = list(logs_dir.glob('*.log'))
        if not log_files:
            print(f"No log files found in {logs_dir}")
            sys.exit(1)
    else:
        log_files = [Path(f) for f in sys.argv[1:]]
    
    # Parse all log files
    print(f"📖 Analyzing {len(log_files)} log file(s)...\n")
    for log_file in log_files:
        print(f"   Parsing: {log_file.name}")
        analysis = analyzer.parse_log_file(log_file)
        if analysis:
            analyses.append(analysis)
    
    if not analyses:
        print("❌ No valid analyses found!")
        sys.exit(1)
    
    # Generate comprehensive report
    report = analyzer.generate_comprehensive_report(analyses)
    print("\n" + report)
    
    # Save report to file
    report_file = Path('logs/workflow-analysis-report.txt')
    report_file.parent.mkdir(exist_ok=True)
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report)
    print(f"\n💾 Report saved to: {report_file}")
    
    # Save JSON for programmatic access
    json_file = Path('logs/workflow-analysis-data.json')
    with open(json_file, 'w', encoding='utf-8') as f:
        # Convert dataclasses to dict for JSON serialization
        json_data = []
        for analysis in analyses:
            analysis_dict = {}
            for key, value in analysis.items():
                if isinstance(value, (PerformanceMetrics, Statistics)):
                    analysis_dict[key] = value.__dict__
                elif isinstance(value, list) and value and isinstance(value[0], LogEntry):
                    analysis_dict[key] = [
                        {
                            'line_number': e.line_number,
                            'content': e.content[:200],
                            'level': e.level,
                            'category': e.category,
                            'event_type': e.event_type
                        }
                        for e in value[:100]  # Limit for JSON size
                    ]
                else:
                    analysis_dict[key] = value
            json_data.append(analysis_dict)
        json.dump(json_data, f, indent=2, default=str)
    print(f"💾 JSON data saved to: {json_file}")


if __name__ == '__main__':
    main()
